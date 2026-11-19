import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/settings_ui.dart';
import '../../core/widgets/widgets.dart';
import '../auth/auth_controller.dart';

Widget _label(String t) => Padding(
  padding: const EdgeInsets.fromLTRB(2, 20, 2, 8),
  child: Text(
    t,
    style: Type.body(13.5, weight: FontWeight.w600, color: Tokens.inkSoft),
  ),
);

/// Edit the signed-in user's own name and phone. Email is the sign-in, so it is shown but locked.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _phone;
  bool _busy = false, _photoBusy = false;
  static final _fieldText = Type.body(16);

  @override
  void initState() {
    super.initState();
    final u = ref.read(authProvider).user;
    _name = TextEditingController(text: '${u?['name'] ?? ''}');
    _phone = TextEditingController(text: '${u?['phone'] ?? ''}');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authProvider.notifier)
          .updateProfile(name: _name.text.trim(), phone: _phone.text.trim());
      if (!mounted) return;
      showInfo(context, context.l10n.profileSaved);
      context.pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _photo(ImageSource? source) async {
    final l = context.l10n;
    final api = ref.read(apiProvider);
    final auth = ref.read(authProvider.notifier);
    setState(() => _photoBusy = true);
    try {
      final Json user;
      if (source == null) {
        user = await api.removeAvatar();
      } else {
        final x = await ImagePicker().pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        if (x == null) return;
        user = await api.uploadAvatar(await x.readAsBytes(), 'avatar.jpg');
      }
      auth.setUser(user);
      if (mounted) {
        showInfo(context, source == null ? l.photoRemoved : l.photoUpdated);
      }
    } on PlatformException {
      if (mounted) showInfo(context, l.photoFailed);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  void _choosePhoto(bool hasPhoto) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Tokens.pageBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.changePhoto, style: Type.display(18)),
              const SizedBox(height: 14),
              SettingsGroup(
                children: [
                  SettingsRow(
                    icon: Icons.photo_library_outlined,
                    title: l.chooseFromLibrary,
                    chevron: false,
                    onTap: () {
                      Navigator.pop(c);
                      _photo(ImageSource.gallery);
                    },
                  ),
                  SettingsRow(
                    icon: Icons.photo_camera_outlined,
                    title: l.takePhoto,
                    chevron: false,
                    onTap: () {
                      Navigator.pop(c);
                      _photo(ImageSource.camera);
                    },
                  ),
                  if (hasPhoto)
                    SettingsRow(
                      icon: Icons.delete_outline_rounded,
                      title: l.removePhoto,
                      danger: true,
                      chevron: false,
                      onTap: () {
                        Navigator.pop(c);
                        _photo(null);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(Json? user) {
    final url = user?['avatarUrl'] as String?;
    final has = url != null && url.isNotEmpty;
    return Center(
      child: Semantics(
        button: true,
        label: context.l10n.changePhoto,
        child: GestureDetector(
          onTap: _photoBusy ? null : () => _choosePhoto(has),
          child: SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ProfileAvatar(name: _name.text, url: url, size: 104),
                ),
                if (_photoBusy)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .7),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Tokens.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: Tokens.pageBg, width: 3),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = ref.watch(authProvider).user;
    return SubPage(
      title: l.editProfile,
      footer: FilledButton(
        onPressed: _busy ? null : _save,
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Text(l.saveChanges),
      ),
      children: [
        const SizedBox(height: 8),
        _avatar(user),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(l.profileName),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                style: _fieldText,
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    (v ?? '').trim().length < 2 ? l.nameTooShort : null,
              ),
              _label(l.profilePhone),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [LengthLimitingTextInputFormatter(30)],
                style: _fieldText,
              ),
              _label(l.profileEmail),
              TextFormField(
                initialValue: '${user?['email'] ?? ''}',
                enabled: false,
                style: _fieldText.copyWith(color: Tokens.disabledInk),
                decoration: const InputDecoration(
                  fillColor: Tokens.neutralTint,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
                child: Text(
                  l.profileEmailNote,
                  style: Type.body(12.5, color: Tokens.inkMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Account deletion: says what goes and what stays, then asks for a typed confirmation (plus the password when the account has one).
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends ConsumerState<DeleteAccountScreen> {
  final _confirm = TextEditingController(), _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _confirm.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _hasPassword => ref.read(authProvider).user?['hasPassword'] != false;

  bool get _ready =>
      _confirm.text.trim() == 'DELETE' &&
      (!_hasPassword || _password.text.isNotEmpty);

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(apiProvider)
          .postEmpty(
            '/users/me/delete',
            body: {
              'confirmation': _confirm.text.trim(),
              if (_hasPassword) 'password': _password.text,
            },
          );
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      showInfo(context, context.l10n.accountDeleted);
      context.go('/login');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, e);
      }
    }
  }

  Widget _point(IconData icon, String text, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Type.body(14.5, color: Tokens.inkSoft, height: 1.45),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SubPage(
      title: l.deleteAccountTitle,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Tokens.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: _ready && !_busy ? _delete : null,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(l.deleteForever),
          ),
          TextButton(
            onPressed: _busy ? null : () => context.pop(),
            child: Text(l.deleteCancel),
          ),
        ],
      ),
      children: [
        Text(
          l.deleteIntro,
          style: Type.body(15, color: Tokens.inkSoft, height: 1.5),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Tokens.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.deleteRemovedHeading,
                style: Type.body(14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _point(Icons.close_rounded, l.deleteRemoved1, Tokens.danger),
              _point(Icons.close_rounded, l.deleteRemoved2, Tokens.danger),
              _point(Icons.close_rounded, l.deleteRemoved3, Tokens.danger),
              const Divider(height: 24, color: Tokens.neutralTint),
              Text(
                l.deleteKeptHeading,
                style: Type.body(14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _point(Icons.check_rounded, l.deleteKept1, Tokens.inkMuted),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 12, 2, 0),
          child: Text(
            l.deleteActiveNote,
            style: Type.body(13, color: Tokens.inkMuted, height: 1.5),
          ),
        ),
        if (_hasPassword) ...[
          _label(l.deletePasswordLabel),
          TextField(
            controller: _password,
            obscureText: true,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
          ),
        ],
        _label(l.deleteTypeLabel),
        TextField(
          controller: _confirm,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(hintText: l.deleteTypeHint),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

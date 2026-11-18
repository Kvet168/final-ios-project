-- Profile photo: points at an image the user uploaded to the media table ("/api/media/{id}").
ALTER TABLE users ADD COLUMN avatar_url text;

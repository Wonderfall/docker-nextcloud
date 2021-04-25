# wonderfall/nextcloud

New version of my Nextcloud image, still in testing:
- Fetching PHP/nginx from their official images.
- Does not use any privilege at any time, even at startup.
- Much easier to maintain thanks to multi-stages build.
- Includes hardened_malloc, a hardened memory allocator.
- Does not include imagick, samba, etc. by default.

Goals: simple, lean, and secure.

Be aware this image is not ready yet for production use. While it might work, please note a fresh install from the previous image is recommended. If you intend to migrate, please back up your data.

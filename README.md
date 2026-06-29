# Time Tracker

Place this app in `nextcloud/apps/`.

## Build Requirements

- `make`
- `php` for Composer fallback installation
- `composer`, or `curl` plus `php` so the Makefile can download Composer locally
- `npm`
- `tar` for source and app store archives

The JavaScript build is tested with Node.js 20 and npm 10. Newer runtimes may work, but npm can warn when package engine ranges do not match the supported build runtime.

## Building the App

Run the full build from the app root:

```sh
make
```

The Makefile runs Composer when `composer.json` is present and runs `npm ci && npm run build` for the JavaScript assets in `js/`.

Tool commands can be overridden without editing the Makefile:

```sh
make PHP=/usr/local/bin/php COMPOSER=/usr/local/bin/composer NPM=/usr/local/bin/npm
```

If Composer is not installed, the Makefile downloads Composer into `build/tools/` and runs it with `php`. The PHP command defaults to `php`, not a versioned binary such as `php-8.2`.

## Frontend Build

From `js/`:

```sh
npm ci
npm run build
```

Useful scripts:

- `npm run build`: production Webpack build
- `npm run build:dev`: development Webpack build
- `npm run audit`: audit the lockfile without modifying dependencies

## Packaging

Build source and app store archives:

```sh
make dist
```

The archive command defaults to `tar`. If your platform needs a different command or tar option set, override it:

```sh
make appstore TAR=gtar
make appstore TAR_OWNER_ARGS=
```

## Downloadable CI Package

The `Package` GitHub Actions workflow builds a downloadable appstore tarball.

To build one on demand:

1. Open the repository on GitHub.
2. Go to **Actions**.
3. Select **Package**.
4. Click **Run workflow**.
5. Download the `timetracker-appstore-package` artifact from the completed run.

The artifact contains:

- `timetracker.tar.gz`: app package for `nextcloud/apps/`
- `timetracker.tar.gz.sha256`: checksum for the package

The same workflow also runs when a tag matching `v*` is pushed.

## Running Tests

The PHP tests need a Nextcloud server checkout because the test bootstrap loads Nextcloud internals from `lib/base.php`.

Create a local test harness:

```sh
git clone --recursive --branch stable34 https://github.com/nextcloud/server.git nextcloud
cd nextcloud
composer install --no-dev --prefer-dist --no-interaction
cd vendor-bin/phpunit
composer install --prefer-dist --no-interaction
cd ../../
php occ maintenance:install --database sqlite --admin-user admin --admin-pass admin
cd /path/to/timetracker
make nextcloud-link NEXTCLOUD_ROOT=/path/to/nextcloud
cd /path/to/nextcloud
php occ app:enable timetracker
cd /path/to/timetracker
make test NEXTCLOUD_ROOT=/path/to/nextcloud
```

When the app already lives under `nextcloud/apps/timetracker`, the shorter form is:

```sh
make test
```

The Makefile defaults to Nextcloud's PHPUnit binary at `NEXTCLOUD_ROOT/vendor-bin/phpunit/vendor/bin/phpunit`. Override `PHPUNIT=/path/to/phpunit` if needed.

When the app is not physically located at `nextcloud/apps/timetracker`, either create the symlink yourself or use:

```sh
make nextcloud-link NEXTCLOUD_ROOT=/path/to/nextcloud
```

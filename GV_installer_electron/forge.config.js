const { FusesPlugin } = require('@electron-forge/plugin-fuses');
const { FuseV1Options, FuseVersion } = require('@electron/fuses');
const path = require('path');

module.exports = {
  packagerConfig: {
    asar: {
      unpack: [
			'**/assets/create-desktop-shortcuts/**',
	        '**/assets/GV_icon.ico',
			'**/assets/GV_icon.png',
			'**/assets/GV_icon.icns',
			],
    },
	icon: path.join(__dirname, 'assets', 'GV_icon'),  // no file extension needed, will be chosen automatically
	arch: ['x64', 'arm64'], // to allow both macos architectures
  },
  rebuildConfig: {},
  makers: [
    {
      name: '@electron-forge/maker-squirrel',	// for Windows installer (.exe)
      config: {
		certificateFile: './cert.pfx',
		certificatePassword: process.env.CERTIFICATE_PASSWORD,
		name: 'GenomicViewer',
		authors: 'Sara Lago - Eurac Research',
        skipCreateDesktopShortcut: true,
        skipCreateStartMenuShortcut: true,
		},
    },
    {
      name: '@electron-forge/maker-zip',
      platforms: ['darwin'],
	  arch: ['x64', 'arm64'], // to allow both macos architectures
    },
    {
      name: '@electron-forge/maker-deb',	// Linux Debian-based (.deb)
      config: {
		  options: {
			maintainer: 'Sara Lago <sara.lago@eurac.edu>',
			homepage: 'https://github.com/sarlago/ShinyApps',
			fpm: [
            "--deb-sign",
            "--key=6AE934E9EA6E27DF"
          ]
			},
		},
    },
	{
      name: '@electron-forge/maker-rpm',	// Linux Fedora (.rpm)
      config: {
        options: {
          fpm: [
            "--rpm-sign",
            "--key=6AE934E9EA6E27DF"
          ]
        }
      }
	},
    {
      name: '@electron-forge/maker-dmg',         // macOS .dmg
      config: {
        name: 'GenomicViewer',
		volumeName: 'GenomicViewer',
      },
	  arch: ['x64', 'arm64'], // to allow both macos architectures
    },
  ],
    publishers: [
    {
      name: '@electron-forge/publisher-github',
      config: {
        repository: {
          owner: 'sarlago',
          name: 'Electron_GV_installer',
        },
        prerelease: false,
      },
    },
  ],
  plugins: [
    {
      name: '@electron-forge/plugin-auto-unpack-natives',
      config: {},
    },
    // Fuses are used to enable/disable various Electron functionality
    // at package time, before code signing the application
    //new FusesPlugin({
      //version: FuseVersion.V1,
      //[FuseV1Options.RunAsNode]: false,
      //[FuseV1Options.EnableCookieEncryption]: true,
      //[FuseV1Options.EnableNodeOptionsEnvironmentVariable]: false,
      //[FuseV1Options.EnableNodeCliInspectArguments]: false,
      //[FuseV1Options.EnableEmbeddedAsarIntegrityValidation]: true,
      //[FuseV1Options.OnlyLoadAppFromAsar]: true,
    //}),
  ],
};

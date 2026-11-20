// Configuration macros

/* #undef CONFIG_RELEASE */

#if !(CONFIG_RELEASE)
# define CONFIG_RELEASE 0
#endif
 
#if CONFIG_RELEASE
# define CONFIG_TYPE "release"
#else
# define CONFIG_TYPE "development"
#endif

#define CONFIG_BRANCH "main"
#define CONFIG_COMMIT "dev"

/* #undef CONFIG_CURSEFORGE_API_KEY */

#ifndef CONFIG_CURSEFORGE_API_KEY 
# define CONFIG_CURSEFORGE_API_KEY nil
#endif


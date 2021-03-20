#include "common/common.h"
#include "common/json.h"
#include "openssl.h"
#include "macho.h"
#include "bundle.h"
#include <libgen.h>
#include <dirent.h>
#include <getopt.h>
#include "MyCPPClass.hpp"
#include "optparse.h"

struct optparse_long longopts[] = {
    { "force",            'f', OPTPARSE_NONE },
    { "pkey",            'k', OPTPARSE_REQUIRED },
    { "password",        'p', OPTPARSE_REQUIRED },
    { "prov",            'm', OPTPARSE_REQUIRED },
    { "output",            'o', OPTPARSE_REQUIRED },
    { "verbose",        'v', OPTPARSE_NONE },
    { "dylib",            'l', OPTPARSE_REQUIRED  },
    { "bundleid",        'b', OPTPARSE_REQUIRED },
    { "bundlename",        'n', OPTPARSE_REQUIRED },
    { "ziplevel",        'z', OPTPARSE_REQUIRED  },
    { "debug",            'd', OPTPARSE_NONE },
    { "cert",            'c', OPTPARSE_REQUIRED },
    { "entitlements",    'e', OPTPARSE_REQUIRED },
	{ "weak",			'w', OPTPARSE_NONE  },
	{ "install",		'i', OPTPARSE_NONE  },
	{ "quiet",			'q', OPTPARSE_NONE  },
	{ "help",			'h', OPTPARSE_NONE  },
	{ 0 }
};

int usage()
{
	ZLog::Print("Usage: zsign [-options] [-k privkey.pem] [-m dev.prov] [-o output.ipa] file|folder\n");
	ZLog::Print("options:\n");
	ZLog::Print("-k, --pkey\t\tPath to private key or p12 file. (PEM or DER format)\n");
	ZLog::Print("-m, --prov\t\tPath to mobile provisioning profile.\n");
	ZLog::Print("-c, --cert\t\tPath to certificate file. (PEM or DER format)\n");
	ZLog::Print("-d, --debug\t\tGenerate debug output files. (.zsign_debug folder)\n");
	ZLog::Print("-f, --force\t\tForce sign without cache when signing folder.\n");
	ZLog::Print("-o, --output\t\tPath to output ipa file.\n");
	ZLog::Print("-p, --password\t\tPassword for private key or p12 file.\n");
	ZLog::Print("-b, --bundleid\t\tNew bundle id to change.\n");
	ZLog::Print("-n, --bundlename\tNew bundle name to change.\n");
	ZLog::Print("-e, --entitlements\tNew entitlements to change.\n");
	ZLog::Print("-z, --ziplevel\t\tCompressed level when output the ipa file. (0-9)\n");
	ZLog::Print("-l, --dylib\t\tPath to inject dylib file.\n");
	ZLog::Print("-w, --weak\t\tInject dylib as LC_LOAD_WEAK_DYLIB.\n");
	ZLog::Print("-i, --install\t\tInstall ipa file using ideviceinstaller command for test.\n");
	ZLog::Print("-q, --quiet\t\tQuiet operation.\n");
	ZLog::Print("-v, --version\t\tShow version.\n");
	ZLog::Print("-h, --help\t\tShow help.\n");

	return -1;
}

int zsign(int argc, char * argv[])
{
	ZTimer gtimer;
    
	bool bForce = true;
	bool bInstall = false;
	bool bWeakInject = false;
	uint32_t uZipLevel = 5;

	string strCertFile;
	string strPKeyFile;
	string strProvFile;
	string strPassword;
	string strBundleId;
    string strBundleVersion;
    string strDisplayName;
    string strEntitlementsFile;
    string strOutputFile;
    string fromIpaPath;

    for (int i = 0; i < argc; i += 2) {
        
        char* option = argv[i];
        if (strcmp(option, "-k") == 0) {
            
            strPKeyFile = argv[i+1];
            
        } else if (strcmp(option, "-c") == 0) {
            
            strCertFile = argv[i+1];
            
        } else if (strcmp(option, "-p") == 0) {
            
            strPassword = argv[i+1];
            
        } else if (strcmp(option, "-m") == 0) {
            
            strProvFile = argv[i+1];
            
        } else if (strcmp(option, "-o") == 0) {
            
            strOutputFile = argv[i+1];
            
        } else if (strcmp(option, "-v") == 0) {
            
            strBundleVersion = argv[i+1];
            
            
        } else if (strcmp(option, "-b") == 0) {
            
            strBundleId = argv[i+1];
            
            
        } else if (strcmp(option, "-n") == 0) {
            
            strDisplayName = argv[i+1];
            
            
        } else if (strcmp(option, "-z") == 0) {
            
            uZipLevel = atoi(argv[i+1]);
            
            
        } else if (strcmp(option, "-i") == 0) {
            
            fromIpaPath = argv[i+1];
        
        }

    }

    string strPath = fromIpaPath;
    
	if (!IsFileExists(strPath.c_str()))
	{
		ZLog::ErrorV(">>> Invalid Path! %s\n", strPath.c_str());
		return -1;
	}

	bool bZipFile = false;
	if (!IsFolder(strPath.c_str()))
	{
		bZipFile = IsZipFile(strPath.c_str());
		if (!bZipFile)
		{ //macho file
			ZMachO macho;
			if (macho.Init(strPath.c_str()))
			{
				macho.Free();
			}
			return 0;
		}
	}

	ZTimer timer;
	ZSignAsset zSignAsset;
	if (!zSignAsset.Init(strCertFile, strPKeyFile, strProvFile, strEntitlementsFile, strPassword))
	{
		return -2;
	}


    MyCPPClass *temp = new MyCPPClass();
    temp->init();
    //temp->getAppCachePath((char* )fromIpaPath.c_str())
    char* appCachePath = (char* )fromIpaPath.c_str();
    
    //unzip
    bool bEnableCache = true;
	string strFolder = GetCanonicalizePath(appCachePath);
	if (bZipFile)
	{ //ipa file
		bForce = true;
		bEnableCache = false;
		ZLog::PrintV(">>> Unzip:\t%s (%s) -> %s ... \n", strPath.c_str(), GetFileSizeString(strPath.c_str()).c_str(), strFolder.c_str());
		if (!temp->unzip((char*)strPath.c_str(), appCachePath))
		{
			ZLog::ErrorV(">>> Unzip Failed!\n");
			return -3;
		}
        
		timer.PrintResult(true, ">>> Unzip OK!");
	}
    
    //resign and inject libs
	timer.Reset();
	ZAppBundle bundle;
    bool bRet = bundle.SignFolder(&zSignAsset, strFolder, strBundleVersion, strBundleId, strDisplayName, bForce, bWeakInject, bEnableCache);
	timer.PrintResult(bRet, ">>> Signed %s!", bRet ? "OK" : "Failed");
    if (bRet == false)
    {
        return -7;
    }


	if (!strOutputFile.empty())
	{
		timer.Reset();
        string strBaseFolder = bundle.m_strAppFolder;
        //move signd file to dir
        bool res = temp->moveFile((char *)strBaseFolder.c_str(), (char *)strOutputFile.c_str(), "");
        if (!res) {
            return -8;
        }
		timer.PrintResult(true, ">>> Archive OK! (%s)", GetFileSizeString(strOutputFile.c_str()).c_str());
    
    } else {
    
        return -10;
    }

    delete temp;
	gtimer.Print(">>> Done.");
	return 0;
}

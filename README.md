# ModGuardian
A set of tools to implement some form of copy protection for Project Zomboid mods.

# THIS IS A WORK IN PROGRESS
While you are very welcome to experiment with these tools, to give feedback and to report issues, this project is still in very early development phase.

Don't publish mods obfuscated using this project unless you checked thoroughly they are working perfectly fine.

# Supported Platforms
As of now, I've only tested this project on Linux, but I see no reason why it couldn't be made to work on Windows or Mac OS X and I'm willing to make it work on these platforms too. If you're interested in giving it a try, feel free to open [issues](https://github.com/quarantin/ModGuardian/issues) in case you're having problems.

# Features
- Heavy obfuscation of your Lua code to prevent edits
- Blacklist players by Steam IDs (Your mods will **NOT** work for them)
- Blacklist servers who repack your mods in modpacks (Your mods will **NOT** work on these servers)
- Make your mod exclusive to a list of servers (Your mods will **ONLY** work on these servers)
- Provide a library mod to help you enforce the previously mentioned features

# Usage
In order to use ModGuardian to protect your mods, simply follow these steps:
1) Install ModGuardian from workshop (I haven't published it yet, so for now you'll have to take the one from this repo and install it manually).
2) Assuming you have a working python3 interpreter and you already cloned this repo, you can do something like this to install the ModGuardian.py script:
```
python3 -m venv env
. env/bin/activate
pip install -r requirements.txt
```
3) Add this to your mod.info:
```
require=ModGuardian
```
4)  Add this code anywhere in your mod, ideally at top level/global scope, and don't forget to replace the values accordingly:
```
require("ModGuardian/ModGuardian")({
        modID = "YourModID",           -- Replace "YourModID" with the ID from your mod.info
        workshopID = "YourWorkshopID", -- Replace "YourWorkshopID" with your workshop identifier
        playerBlacklist = {
            "750043204923432"          -- Steam ID. Clear this list if you don't have anyone you want blacklisted
        },
        serverBlacklist = {
            "1.2.3.4"                  -- Server IP. Clear this list if you don't have any server you want blacklisted
        },
        exclusiveServers = {
            "2.3.4.5"                  -- Server IP. Clear this list if you don't need your mod to be exclusive to your server
        }
})
```
5) Obfuscate your mod:
```
python3 ModGuardian.py /path/to/your/mod/
```
It will generate an obfuscated copy of your mod at the following location: `/path/to/your/mod.obfuscated`

Please note `/path/to/your/mod` should point to the top folder of your mod, where the mod.info file is located.

# Caveats
As sexy as it might sound, copy protection is a topic which has been under heavy research for more than 20 years. No one has been able so far to come up with a solution that fully protect your intellectual property. All the current solutions rely on techniques that can usually be defeated quite easily by anyone with the proper skills. Unfortunately this is also the case for this project.

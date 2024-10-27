import std.stdio;
import std.getopt;
import std.array: split, join;
import std.algorithm: canFind, countUntil;
import std.conv: to;
import std.file: exists, mkdir;
import std.process: spawnShell, wait;

import core.stdc.stdlib: getenv, exit;

import sily.getopt;
import sily.path: fixPath;

bool returnPath = false;

int main(string[] args) {
    string removeName = "";
    string setName = "";
    string editor = "";
    bool doList = false;

    GetoptResult help = getopt(
        args,
        std.getopt.config.bundling, std.getopt.config.passThrough,
        "set|s", "Sets new path for config", &setName,
        "add|a", "Alias for set", &setName,
        "remove|r", "Removes config path", &removeName,
        "editor|e", "Open with custom editor command", &editor,
        "list|l", "Lists all configs", &doList,
        "path|p", "Print config path to stdout and exit", &returnPath
    );

    if (help.helpWanted) {
        Option[] usage = [
            customOption("Open", "confed nvim"),
            customOption("Set", "confed -s nvim ~/.config/nvim/"),
            customOption("Remove", "confed -r nvim"),
            customOption("List", "confed -l"),
            customOption("Editor", "confed -e \"nvim --noplugin --\" nvim"),
            customOption("Use with shell", "VP=$(confed -p nvim); cd $VP; nvim $VP"),
        ];
        printGetopt("confed [args]", "Options", help.options, "Usage", usage);
        return 0;
    }

    checkPath();
    Config[] conf = configRead();

    if (doList) {
        foreach (Config c; conf) {
            writeln(c.name, ": \"", c.path, "\"");
        }
        return 0;
    }

    string arg = args[1..$].join();

    if (setName != "") {
        int namePos = conf.findName(setName);
        if (namePos != -1) {
            conf[namePos].path = arg;
        } else {
            conf ~= Config(setName, arg);
        }
        configWrite(conf);
        return 0;
    }

    if (removeName != "") {
        int namePos = conf.findName(removeName);
        if (namePos != -1) {
            Config c = conf[namePos];
            conf = conf.split(c).join();
        } else {
            if (!returnPath) writeln("Error, can't find config with name \"", removeName, "\".");
            return 1;
        }
        configWrite(conf);
        return 0;
    }

    if (arg == "") {
        if (!returnPath) writeln("Error, missing config name.");
        return 1;
    }

    int namePos = conf.findName(arg);
    if (namePos == -1) {
        if (!returnPath) writeln("Error, can't find config with name \"", arg, "\".");
        return 1;
    }

    if  (returnPath) {
        writeln(conf[namePos].path);
        return 0;
    }

    if (getenv("EDITOR") == null && editor == "") {
        write("$EDITOR not set, please enter editor command.\nEditor: ");
        editor = readln()[0..$-1];
    }
    editor = editor == "" ? getenv("EDITOR").to!string : editor;
    // writeln(getenv("EDITOR"));
    // writeln(editor ~ " " ~ conf[namePos].path);
    wait(spawnShell(editor ~ " " ~ conf[namePos].path));

    return 0;
}

string configPath = "~/.config/confed/config_list";
string configPathOnly = "~/.config/confed";
/* Config structure:
   Name//////Path
*/

void checkPath() {
    if (!configPathOnly.fixPath.exists()) {
        mkdir(configPathOnly.fixPath);
    }
    if (!configPath.fixPath.exists()) {
        File f = File(configPath.fixPath, "w+");
        f.close();
    }
}

void configWrite(Config[] arr) {
    string _out;
    for (int i = 0; i < arr.length; ++i) {
        Config c = arr[i];
        _out ~= c.name ~ " // " ~ c.path;
        if (i + 1 != arr.length) _out ~= "\n";
    }
    File f = File(configPath.fixPath, "w+");
    f.write(_out);
    f.close();
}

Config[] configRead() {
    File f = File(configPath.fixPath, "r+");
    Config[] arr;
    int i = 1;
    while (!f.eof) {
        string line = f.readln();
        if (line == "") break;
        if (!f.eof) line = line[0..$-1];
        string[] l = line.split(" // ");

        if (l.length != 2) {
            if (!returnPath) writeln(configPath.fixPath, ":", i, " Error, invalid line, expected \"name // path\", got \"", line, "\".");
            exit(1);
        }
        string name = l[0];
        string path = l[1];
        arr ~= Config(name, path);
        ++i;
    }
    f.close();
    return arr;
}

int findPath(Config[] cf, string p) {
    for (int i = 0; i < cf.length; ++i) {
        Config c = cf[i];
        if (c.path == p) {
            return i;
        }
    }
    return -1;
}

int findName(Config[] cf, string n) {
    for (int i = 0; i < cf.length; ++i) {
        Config c = cf[i];
        if (c.name == n) {
            return i;
        }
    }
    return -1;
}

struct Config {
    string name;
    string path;
}

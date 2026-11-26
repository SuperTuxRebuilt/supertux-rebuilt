//  Eispinguin
//  Copyright (C) 2026 AnatolyStev
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

package editor;

import haxe.Json;
import openfl.Assets;

class MusicTrack
{
    public var name:String;
    public var asset:String;

    public function new(name:String, asset:String)
    {
        this.name = name;
        this.asset = asset;
    }
}

class MusicLibrary
{
    public var tracks:Array<MusicTrack> = [];

    public function new()
    {
        tracks.push(new MusicTrack("No Music", ""));
    }

    public static function load(path:String):MusicLibrary
    {
        var library = new MusicLibrary();
        var root:Dynamic = Json.parse(Assets.getText(path));
        var entries:Array<Dynamic> = cast Reflect.field(root, "tracks");

        if (entries != null)
        {
            for (entry in entries)
            {
                var name = Std.string(entry.name);
                var asset = Std.string(entry.asset);

                if (asset == "")
                {
                    continue;
                }

                library.tracks.push(new MusicTrack(name, asset));
            }
        }

        return library;
    }

    public function findOrAdd(asset:String):Int
    {
        for (i in 0...tracks.length)
        {
            if (tracks[i].asset == asset)
            {
                return i;
            }
        }

        tracks.push(new MusicTrack("Custom Music", asset));

        return tracks.length - 1;
    }
}
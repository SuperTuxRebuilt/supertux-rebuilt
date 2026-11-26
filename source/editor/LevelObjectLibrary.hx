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
import openfl.display.BitmapData;

class LevelObjectDefinition
{
    public var id:String;
    public var name:String;
    public var image:String;
    public var bitmap:BitmapData;

    public function new(id:String, name:String, image:String, bitmap:BitmapData)
    {
        this.id = id;
        this.name = name;
        this.image = image;
        this.bitmap = bitmap;
    }
}

class LevelObjectLibrary
{
    public var definitions:Array<LevelObjectDefinition> = [];

    public function new()
    {
    }

    public static function load(path:String):LevelObjectLibrary
    {
        var library = new LevelObjectLibrary();

        var root:Dynamic = Json.parse(Assets.getText(path));
        var entries:Array<Dynamic> = cast Reflect.field(root, "objects");

        if (entries != null)
        {
            for (entry in entries)
            {
                var id = Std.string(entry.id);
                var name = Std.string(entry.name);
                var image = Std.string(entry.image);

                var bitmap = Assets.getBitmapData(image);

                library.definitions.push(new LevelObjectDefinition(id, name, image, bitmap));
            }
        }

        return library;
    }

    public function getById(id:String):LevelObjectDefinition
    {
        for (definition in definitions)
        {
            if (definition.id == id)
            {
                return definition;
            }
        }

        throw "Unknown object ID: " + id;
    }
}
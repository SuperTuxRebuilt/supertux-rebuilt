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

package util;

import collision.GroundPiece.GroundPieceType;
import haxe.Json;
import openfl.Assets;
import openfl.display.BitmapData;

class GroundPieceDefinition
{
    public var id:String;
    public var name:String;

    public var bitmap:BitmapData;
    public var collisionMask:BitmapData;

    public var type:GroundPieceType;

    public function new(id:String, name:String, bitmap:BitmapData, type:GroundPieceType, ?collisionMask:BitmapData)
    {
        this.id = id;
        this.name = name;
        this.bitmap = bitmap;
        this.type = type;
        this.collisionMask = collisionMask;
    }
}

class GroundPieceLibrary
{
    public var definitions:Array<GroundPieceDefinition> = [];

    public function new()
    {
    }

    public static function load(path:String):GroundPieceLibrary
    {
        var library = new GroundPieceLibrary();

        var root:Dynamic = Json.parse(Assets.getText(path));

        var entries:Array<Dynamic> = cast Reflect.field(root, "groundpieces");

        if (entries == null)
        {
            throw "groundpieces.json is missing its groundpieces array.";
        }

        for (entry in entries)
        {
            var id = Std.string(entry.id);
            var name = Std.string(entry.name);
            var imagePath = Std.string(entry.image);
            var typeName = Std.string(entry.type);

            var bitmap:BitmapData = Assets.getBitmapData(imagePath);

            var collisionMask:BitmapData = null;

            var maskPath:Dynamic = Reflect.field(entry, "collisionMask");

            if (maskPath != null)
            {
                collisionMask = Assets.getBitmapData(Std.string(maskPath));
            }

            var type:GroundPieceType;

            switch (typeName)
            {
                case "ground":
                    type = GroundPieceType.ground;
                case "solid":
                    type = GroundPieceType.solid;
                case "transparent":
                    type = GroundPieceType.transparent;
                default:
                    throw "Unknown Ground Piece type: " + typeName;
            }

            library.definitions.push(new GroundPieceDefinition(id, name, bitmap, type, collisionMask));
        }

        return library;
    }

    public function getById(id:String):GroundPieceDefinition
    {
        for (definition in definitions)
        {
            if (definition.id == id)
            {
                return definition;
            }
        }

        throw "Unknown Ground Piece ID: " + id;
    }

    public function getIndex(id:String):Int
    {
        for (i in 0...definitions.length)
        {
            if (definitions[i].id == id)
            {
                return i;
            }
        }

        return -1;
    }
}
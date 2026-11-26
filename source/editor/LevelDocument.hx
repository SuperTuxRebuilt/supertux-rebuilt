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

class LevelPiecePlacement
{
    public var id:String;
    public var x:Int;
    public var y:Int;

    public function new(id:String, x:Int, y:Int)
    {
        this.id = id;
        this.x = x;
        this.y = y;
    }
}

class ObjectPlacement
{
    public var id:String;
    public var x:Int;
    public var y:Int;

    public function new(id:String, x:Int, y:Int)
    {
        this.id = id;
        this.x = x;
        this.y = y;
    }
}

class LevelDocument
{
    public var width:Int;
    public var height:Int;

    public var playerX:Float = 64;
    public var playerY:Float = 64;

    public var music:String = "";

    public var gradientTop:String = "0x8080FF";
    public var gradientBottom:String = "0xFFFFFF";

    public var pieces:Array<LevelPiecePlacement> = [];
    public var objects:Array<ObjectPlacement> = [];

    public function new(width:Int, height:Int)
    {
        this.width = width;
        this.height = height;
    }

    public static function fromJson(content:String):LevelDocument
    {
        var root:Dynamic = Json.parse(content);
        var document = new LevelDocument(Std.int(root.width), Std.int(root.height));
        var player:Dynamic = Reflect.field(root, "player");

        if (player != null)
        {
            document.playerX = player.x;
            document.playerY = player.y;
        }

        var music:Dynamic = Reflect.field(root, "music");

        if (music != null) 
        {
            document.music = Std.string(music);
        }

        var gradientTop:Dynamic = Reflect.field(root, "gradientTop");
        var gradientBottom:Dynamic = Reflect.field(root, "gradientBottom");

        if (gradientTop != null)
        {
            document.gradientTop = Std.string(gradientTop);
        }

        if (gradientBottom != null)
        {
            document.gradientBottom = Std.string(gradientBottom);
        }

        var entries:Array<Dynamic> = cast Reflect.field(root, "pieces");

        if (entries != null)
        {
            for (entry in entries)
            {
                document.pieces.push(new LevelPiecePlacement(Std.string(entry.id), Std.int(entry.x), Std.int(entry.y)));
            }
        }

        var objectEntries:Array<Dynamic> = cast Reflect.field(root, "objects");

        if (objectEntries != null)
        {
            for (entry in objectEntries)
            {
                document.objects.push(new ObjectPlacement(Std.string(entry.id), Std.int(entry.x), Std.int(entry.y)));
            }
        }

        return document;
    }

    public function toJson():String
    {
        var pieceData:Array<Dynamic> = [];
        var objectData:Array<Dynamic> = [];

        for (piece in pieces)
        {
            pieceData.push({id: piece.id, x: piece.x, y: piece.y});
        }

        for (object in objects)
        {
            objectData.push({id: object.id, x: object.x, y: object.y});
        }

        return Json.stringify({width: width, height: height, player: {x: playerX, y: playerY}, music: music, pieces: pieceData, objects: objectData, gradientTop: gradientTop, gradientBottom: gradientBottom}, null, "  ");
    }
}
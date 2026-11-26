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

import collision.GroundPiece;
import collision.TerrainManager;
import editor.LevelDocument;
import openfl.Assets;
import util.GroundPieceDefinition;

typedef TerrainLevel =
{
    var terrain:TerrainManager;

    var playerX:Float;
    var playerY:Float;

    var music:String;

    var gradientBottom:String;
    var gradientTop:String;
}

class TerrainLevelLoader
{
    public static function load(path:String, library:GroundPieceLibrary):TerrainLevel
    {
        var document = LevelDocument.fromJson(Assets.getText(path));
        var terrain = new TerrainManager(document.width, document.height);
        var pieces:Array<GroundPiece> = [];

        for (placement in document.pieces)
        {
            var definition = library.getById(placement.id);

            pieces.push(new GroundPiece(definition.bitmap, placement.x, placement.y, definition.type, definition.collisionMask));
        }

        terrain.addPieces(pieces);

        return {terrain: terrain, playerX: document.playerX, playerY: document.playerY, music: document.music, gradientTop: document.gradientTop, gradientBottom: document.gradientBottom};
    }
}
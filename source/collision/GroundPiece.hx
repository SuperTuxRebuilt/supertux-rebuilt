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

package collision;

import openfl.display.BitmapData;

enum abstract GroundPieceType(Int) from Int to Int
{
    var ground = 1;
    var solid = 2;
    var transparent = 3;
}

class GroundPiece
{
    public var bitmap(default, null):BitmapData;

    public var collisionMask(default, null):BitmapData;

    public var x:Int;
    public var y:Int;

    public var type:GroundPieceType;

    public function new(bitmap:BitmapData, x:Int, y:Int, type:GroundPieceType, ?collisionMask:BitmapData)
    {
        if (bitmap == null)
        {
            throw "Groundpiece requires an image!";
        }

        if (collisionMask != null)
        {
            if (collisionMask.width != bitmap.width || collisionMask.height != bitmap.height)
            {
                trace("Collision mask must have the same dimensions as it's image!");
            }
        }

        this.bitmap = bitmap;
        this.collisionMask = collisionMask;

        this.x = x;
        this.y = y;

        this.type = type;
    }
}
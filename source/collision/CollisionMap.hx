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

import haxe.io.Bytes;

class CollisionMap
{
    public static inline var empty:Int = 0;
    public static inline var ground:Int = 1;
    public static inline var solid:Int = 2;

    public var width(default, null):Int;
    public var height(default, null):Int;

    public var outsideIsSolid:Bool = true;

    var data:Bytes;

    public function new(width:Int, height:Int)
    {
        if (width <= 0 || height <= 0)
        {
            throw "CollisionMap dimensions must be positive!";
        }

        this.width = width;
        this.height = height;

        data = Bytes.alloc(width * height);
    }

    public inline function getPixel(x:Int, y:Int):Int
    {
        if (x < 0 || x >= width)
        {
            return outsideIsSolid ? solid : empty;
        }

        if (y < 0 || y >= height)
        {
            return empty;
        }

        return data.get(y * width + x);
    }

    public inline function setPixel(x:Int, y:Int, material:Int)
    {
        if (x < 0 || y < 0 || x >= width || y >= height)
        {
            return;
        }

        data.set(y * width + x, material);
    }

    public inline function isSolid(x:Int, y:Int):Bool
    {
        var material = getPixel(x, y);

        return material == ground || material == solid;
    }

    public inline function isDiggable(x:Int, y:Int):Bool
    {
        return getPixel(x, y) == ground;
    }

    public function clear()
    {
        data.fill(0, data.length, empty);
    }
}
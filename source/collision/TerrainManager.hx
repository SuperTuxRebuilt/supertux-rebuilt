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

import collision.GroundPiece;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class TerrainManager
{
    public var width(default, null):Int;
    public var height(default, null):Int;
    public var originX(default, null):Float;
    public var originY(default, null):Float;
    public var sprite(default, null):FlxSprite;
    public var collisionMap(default, null):CollisionMap;
    public var collisionAlphaThreshold:Int = 255;

    var pieces:Array<GroundPiece>;
    var removed:Bytes;
    var renderMask:BitmapData;
    var visibleTypes:Bytes;

    public function new(width:Int, height:Int, originX:Float = 0, originY:Float = 0)
    {
        if (width <= 0 || height <= 0)
        {
            trace("Terrain dimensions must be positive!");
        }

        this.width = width;
        this.height = height;

        this.originX = originX;
        this.originY = originY;

        pieces = [];

        removed = Bytes.alloc(width * height);
        visibleTypes = Bytes.alloc(width * height);

        collisionMap = new CollisionMap(width, height);
        renderMask = new BitmapData(width, height, true, FlxColor.WHITE);
        sprite = new FlxSprite(originX, originY);

        sprite.makeGraphic(width, height, FlxColor.TRANSPARENT, true);
    }

    public function addPiece(piece:GroundPiece)
    {
        if (piece == null)
        {
            return;
        }

        clearRemovedUnderPiece(piece);
        pieces.push(piece);

        rebuildRegion(piece.x, piece.y, piece.bitmap.width, piece.bitmap.height);
    }

    public function addPieces(newPieces:Array<GroundPiece>)
    {
        if (newPieces == null)
        {
            return;
        }

        for (piece in newPieces)
        {
            if (piece == null)
            {
                continue;
            }

            clearRemovedUnderPiece(piece);
            pieces.push(piece);
        }

        rebuildAll();
    }

    public function removePiece(index:Int):Bool
    {
        if (index < 0 || index >= pieces.length)
        {
            return false;
        }

        var piece = pieces[index];

        pieces.splice(index, 1);

        rebuildRegion(piece.x, piece.y, piece.bitmap.width, piece.bitmap.height);

        return true;
    }

    function clearRemovedUnderPiece(piece:GroundPiece)
    {
        for (py in 0...piece.bitmap.height)
        {
            var my = piece.y + py;

            if (my < 0 || my >= height)
            {
                continue;
            }

            for (px in 0...piece.bitmap.width)
            {
                var mx = piece.x + px;

                if (mx < 0 || mx >= width)
                {
                    continue;
                }

                var imageAlpha = alpha(piece.bitmap.getPixel32(px, py));
                var collisionAlpha = 0;

                if (piece.collisionMask != null)
                {
                    collisionAlpha = alpha(piece.collisionMask.getPixel32(px, py));
                }

                if (imageAlpha > 0 || collisionAlpha >= collisionAlphaThreshold)
                {
                    var index = my * width + mx;

                    removed.set(index, 0);

                    renderMask.setPixel32(mx,my, FlxColor.WHITE);
                }
            }
        }
    }

    public function rebuildAll()
    {
        rebuildRegion(0, 0, width, height);
    }

    function rebuildRegion(x:Int, y:Int, regionWidth:Int, regionHeight:Int)
    {
        var left = Std.int(Math.max(0, x));
        var top = Std.int(Math.max(0, y));
        var right = Std.int(Math.min(width, x + regionWidth));
        var bottom = Std.int(Math.min(height, y + regionHeight));

        var w = right - left;
        var h = bottom - top;

        if (w <= 0 || h <= 0)
        {
            return;
        }

        var destination = sprite.pixels;
        destination.lock();
        destination.fillRect(new Rectangle(left, top, w, h), 0x00000000);

        for (py in top...bottom)
        {
            for (px in left...right)
            {
                collisionMap.setPixel(px, py, CollisionMap.empty);
                visibleTypes.set(py * width + px, 0);
            }
        }

        for (piece in pieces)
        {
            var pieceRight = piece.x + piece.bitmap.width;
            var pieceBottom = piece.y + piece.bitmap.height;

            var overlapLeft = Std.int(Math.max(left, piece.x));
            var overlapTop = Std.int(Math.max(top, piece.y));
            var overlapRight = Std.int(Math.min(right, pieceRight));
            var overlapBottom = Std.int(Math.min(bottom, pieceBottom));

            var overlapWidth = overlapRight - overlapLeft;
            var overlapHeight = overlapBottom - overlapTop;

            if (overlapWidth <= 0 || overlapHeight <= 0)
            {
                continue;
            }

            for (py in 0...overlapHeight)
            {
                for (px in 0...overlapWidth)
                {
                    var sx = overlapLeft - piece.x + px;
                    var sy = overlapTop - piece.y + py;

                    var mx = overlapLeft + px;
                    var my = overlapTop + py;

                    var index = my * width + mx;

                    var pixel = piece.bitmap.getPixel32(sx, sy);

                    var imageAlpha = alpha(pixel);

                    if (imageAlpha == 0)
                    {
                        continue;
                    }


                    if (removed.get(index) != 0 && piece.type != GroundPieceType.solid)
                    {
                        continue;
                    }

                    blendPixel(destination, mx, my, pixel);

                    visibleTypes.set(index, piece.type);

                    if (piece.type == GroundPieceType.transparent)
                    {
                        continue;
                    }

                    var collisionPixel = pixel;

                    if (piece.collisionMask != null)
                    {
                        collisionPixel = piece.collisionMask.getPixel32(sx, sy);
                    }

                    var collisionAlpha = alpha(collisionPixel);

                    if (collisionAlpha < collisionAlphaThreshold)
                    {
                        continue;
                    }

                    if (piece.type == GroundPieceType.ground)
                    {
                        collisionMap.setPixel(mx, my, CollisionMap.ground);
                    }
                    else if (piece.type == GroundPieceType.solid)
                    {
                        collisionMap.setPixel(mx, my, CollisionMap.solid);
                    }
                }
            }
        }

        destination.unlock();

        sprite.dirty = true;
    }

    inline function blendPixel(destination:BitmapData, x:Int, y:Int, sourcePixel:Int)
    {
        var sourceAlpha = (sourcePixel >>> 24) & 0xFF;

        if (sourceAlpha == 0)
        {
            return;
        }

        if (sourceAlpha == 255)
        {
            destination.setPixel32(x, y, sourcePixel);
            return;
        }

        var destPixel = destination.getPixel32(x, y);
        var destAlpha = (destPixel >>> 24) & 0xFF;

        if (destAlpha == 0)
        {
            destination.setPixel32(x, y, sourcePixel);
            return;
        }

        var inverseAlpha = 255 - sourceAlpha;
        var outAlphaNumerator = sourceAlpha * 255 + destAlpha * inverseAlpha;

        if (outAlphaNumerator <= 0)
        {
            return;
        }

        var outAlpha = Std.int((outAlphaNumerator + 127) / 255);

        var sr = (sourcePixel >>> 16) & 0xFF;
        var sg = (sourcePixel >>> 8) & 0xFF;
        var sb = sourcePixel & 0xFF;

        var dr = (destPixel >>> 16) & 0xFF;
        var dg = (destPixel >>> 8) & 0xFF;
        var db = destPixel & 0xFF;

        var halfDenominator = Std.int(outAlphaNumerator / 2);

        var outR = Std.int((sr * sourceAlpha * 255 + dr * destAlpha * inverseAlpha + halfDenominator) / outAlphaNumerator);
        var outG = Std.int((sg * sourceAlpha * 255 + dg * destAlpha * inverseAlpha + halfDenominator) / outAlphaNumerator);
        var outB = Std.int((sb * sourceAlpha * 255 + db * destAlpha * inverseAlpha + halfDenominator) / outAlphaNumerator);

        var result = (outAlpha << 24) | (outR << 16) | (outG << 8) | outB;

        destination.setPixel32(x, y, result);
    }

    public function digCircle(centerX:Int, centerY:Int, radius:Int):Int
    {
        if (radius < 0)
        {
            return 0;
        }

        var minX = Std.int(Math.max(0, centerX - radius));
        var minY = Std.int(Math.max(0, centerY - radius));

        var maxX = Std.int(Math.min(width - 1, centerX + radius));
        var maxY = Std.int(Math.min(height - 1, centerY + radius));

        var radiusSquared = radius * radius;

        var changed = 0;

        var dirtyLeft = width;
        var dirtyTop = height;

        var dirtyRight = -1;
        var dirtyBottom = -1;

        for (y in minY...(maxY + 1))
        {
            for (x in minX...(maxX + 1))
            {
                var dx = x - centerX;
                var dy = y - centerY;

                if (dx * dx + dy * dy > radiusSquared)
                {
                    continue;
                }

                var index = y * width + x;

                var visualType = visibleTypes.get(index);
                var collisionType = collisionMap.getPixel(x, y);

                var canDig = visualType == GroundPieceType.ground || visualType == GroundPieceType.transparent || (visualType == 0 && collisionType == CollisionMap.ground);

                if (!canDig)
                {
                    continue;
                }

                if (removed.get(index) != 0)
                {
                    continue;
                }

                removed.set(index, 1);
                renderMask.setPixel32(x, y, 0x00000000);

                changed += 1;

                if (x < dirtyLeft) 
                {
                    dirtyLeft = x;
                }
                if (y < dirtyTop) 
                {
                    dirtyTop = y;
                }

                if (x > dirtyRight)
                {
                    dirtyRight = x;
                }
                if (y > dirtyBottom)
                {
                    dirtyBottom = y;
                }
            }
        }

        if (changed > 0)
        {
            rebuildRegion(dirtyLeft, dirtyTop, dirtyRight - dirtyLeft + 1, dirtyBottom - dirtyTop + 1);
        }

        return changed;
    }

    public function digCircleWorld(worldX:Float, worldY:Float, radius:Int):Int
    {
        var localX = Std.int(Math.floor(worldX - originX));
        var localY = Std.int(Math.floor(worldY - originY));

        return digCircle(localX, localY, radius);
    }

    public inline function isSolidAtWorld(worldX:Float, worldY:Float):Bool
    {
        var x = Std.int(Math.floor(worldX - originX));
        var y = Std.int(Math.floor(worldY - originY));

        return collisionMap.isSolid(x, y);
    }

    public inline function getMaterialAtWorld(worldX:Float, worldY:Float):Int
    {
        var x = Std.int(Math.floor(worldX - originX));
        var y = Std.int(Math.floor(worldY - originY));

        return collisionMap.getPixel(x, y);
    }

    public function resetDigging()
    {
        removed.fill(0, 0, removed.length);
        renderMask.fillRect(new Rectangle(0, 0, width, height), 0xFFFFFFFF);

        rebuildAll();
    }

    inline function alpha(pixel:Int):Int
    {
        return (pixel >>> 24) & 0xFF;
    }

    public function replacePieces(newPieces:Array<GroundPiece>)
    {
        pieces = newPieces.copy();

        removed.fill(0, 0, removed.length);

        renderMask.fillRect(new Rectangle(0, 0, width, height), 0xFFFFFFFF);

        rebuildAll();
    }

    public function movePiece(index:Int, newX:Int, newY:Int)
    {
        if (index < 0 || index >= pieces.length)
        {
            return;
        }

        var piece = pieces[index];

        if (piece.x == newX && piece.y == newY)
        {
            return;
        }

        var oldX = piece.x;
        var oldY = piece.y;

        piece.x = newX;
        piece.y = newY;

        rebuildRegion(oldX, oldY, piece.bitmap.width, piece.bitmap.height);
        rebuildRegion(newX, newY, piece.bitmap.width, piece.bitmap.height);
    }

    public function destroy():Void
    {
        renderMask.dispose();
        sprite.destroy();

        pieces = [];
    }
}
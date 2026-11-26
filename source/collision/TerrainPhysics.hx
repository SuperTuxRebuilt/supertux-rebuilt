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

import flixel.FlxObject;

typedef TerrainMoveResult =
{
    var velocityX:Float;
    var velocityY:Float;

    var grounded:Bool;
    var hitWall:Bool;
    var hitCeiling:Bool;
}

class TerrainPhysics
{
    static inline var epsilon:Float = 0.0001;

    public var terrain(default, null):TerrainManager;

    public var gravity:Float = 1000;
    public var maxFallSpeed:Float = 500;

    public var maxStepUp:Int = 12;
    public var maxStepDown:Int = 12;
    public var groundSnapDistance:Int = 6;

    public function new(terrain:TerrainManager)
    {
        this.terrain = terrain;
    }

    public function move(object:FlxObject, velocityX:Float, velocityY:Float, elapsed:Float):TerrainMoveResult
    {
        var hitWall = false;
        var hitCeiling = false;
        var grounded = false;

        if (elapsed <= 0)
        {
            return {velocityX: velocityX, velocityY: velocityY, grounded: isGrounded(object, groundSnapDistance), hitWall: false, hitCeiling: false};
        }

        if (velocityY >= 0)
        {
            var supportY = findSupportSurface(object, object.x, object.y + object.height, groundSnapDistance, groundSnapDistance);

            if (supportY >= 0)
            {
                object.y = supportY - object.height;
                velocityY = 0;
                grounded = true;
            }
        }

        var dx = velocityX * elapsed;
        var horizontalSteps = Std.int(Math.ceil(Math.abs(dx)));
        var canFollowGround = grounded && velocityY >= 0;

        if (horizontalSteps > 0)
        {
            var stepX = dx / horizontalSteps;

            for (i in 0...horizontalSteps)
            {
                var nextX = object.x + stepX;

                if (canFollowGround)
                {
                    var surfaceY = findSupportSurface(object, nextX, object.y + object.height, maxStepUp, maxStepDown);

                    if (surfaceY >= 0)
                    {
                        object.x = nextX;
                        object.y = surfaceY - object.height;

                        grounded = true;

                        continue;
                    }
                }

                var ignoreBottomRows = !grounded && velocityY > 0 ? 1 : 0;

                if (horizontalEdgeBlocked(object, nextX, object.y, stepX, ignoreBottomRows))
                {
                    var wallX:Int;

                    if (stepX > 0)
                    {
                        wallX = Std.int(Math.floor(nextX + object.width - epsilon));
                        object.x = wallX - object.width;
                    }
                    else
                    {
                        wallX = Std.int(Math.floor(nextX));
                        object.x = wallX + 1;
                    }

                    velocityX = 0;
                    hitWall = true;

                    break;
                }

                object.x = nextX;
                grounded = false;
            }
        }

        if (grounded && velocityY >= 0)
        {
            velocityY = 0;
        }
        else
        {
            velocityY += gravity * elapsed;

            if (velocityY > maxFallSpeed)
            {
                velocityY = maxFallSpeed;
            }
        }

        var dy = velocityY * elapsed;

        var verticalSteps = Std.int(Math.ceil(Math.abs(dy)));

        if (verticalSteps > 0)
        {
            var stepY = dy / verticalSteps;

            for (i in 0...verticalSteps)
            {
                var nextY = object.y + stepY;

                if (verticalEdgeBlocked(object, object.x, nextY, stepY))
                {
                    if (stepY > 0)
                    {
                        var floorY = Std.int(Math.floor(nextY + object.height - epsilon));

                        object.y = floorY - object.height;

                        velocityY = 0;
                        grounded = true;
                    }
                    else
                    {
                        var ceilingY = Std.int(Math.floor(nextY));

                        object.y = ceilingY + 1;

                        velocityY = 0;
                        hitCeiling = true;
                        grounded = false;
                    }

                    break; // nvm after searching ik why this was put here!!!
                }

                object.y = nextY;
            }
        }

        if (velocityY >= 0)
        {
            var finalSurface = findSupportSurface(object, object.x, object.y + object.height, 0, groundSnapDistance);

            if (finalSurface >= 0)
            {
                object.y = finalSurface - object.height;

                velocityY = 0;
                grounded = true;
            }
            else
            {
                grounded = false;
            }
        }

        return {velocityX: velocityX, velocityY: velocityY, grounded: grounded, hitWall: hitWall, hitCeiling: hitCeiling};
    }

    function findSupportSurface(object:FlxObject, x:Float, referenceBottom:Float, maxUp:Int, maxDown:Int):Int
    {
        var left = Std.int(Math.floor(x));
        var right = Std.int(Math.floor(x + object.width - epsilon));

        var startY = Std.int(Math.floor(referenceBottom - maxUp));
        var endY = Std.int(Math.floor(referenceBottom + maxDown));

        var bestSurface = -1;
        var bestDistance:Float = 1e30;

        for (py in startY...(endY + 1))
        {
            var foundSurface = false;

            for (px in left...(right + 1))
            {
                if (solidAt(px, py))
                {
                    foundSurface = true;
                    break;
                }
            }

            if (!foundSurface)
            {
                continue;
            }

            var candidateY = py - object.height;

            if (bodyBlockedAt(object, x, candidateY))
            {
                continue;
            }

            var distance = Math.abs(py - referenceBottom);

            if (distance < bestDistance || (distance == bestDistance && (bestSurface < 0 || py < bestSurface)))
            {
                bestDistance = distance;
                bestSurface = py;
            }
        }

        return bestSurface;
    }

    function bodyBlockedAt(object:FlxObject, x:Float, y:Float):Bool
    {
        var left = Std.int(Math.floor(x));
        var right = Std.int(Math.ceil(x + object.width)) - 1;

        var top = Std.int(Math.floor(y));
        var bottom = Std.int(Math.ceil(y + object.height)) - 1;

        for (py in top...(bottom + 1))
        {
            for (px in left...(right + 1))
            {
                if (solidAt(px, py))
                {
                    return true;
                }
            }
        }

        return false;
    }

    function horizontalEdgeBlocked(object:FlxObject, x:Float, y:Float, direction:Float, ignoreBottomRows:Int = 0):Bool
    {
        var edgeX:Int;

        if (direction > 0)
        {
            edgeX = Std.int(Math.floor(x + object.width - epsilon));
        }
        else
        {
            edgeX = Std.int(Math.floor(x));
        }

        var top = Std.int(Math.floor(y));

        var bottom = Std.int(Math.ceil(y + object.height)) - 1;

        bottom = Std.int(Math.max(top, bottom - ignoreBottomRows));

        for (py in top...(bottom + 1))
        {
            if (solidAt(edgeX, py))
            {
                return true;
            }
        }

        return false;
    }

    function verticalEdgeBlocked(object:FlxObject, x:Float, y:Float, direction:Float):Bool
    {
        var edgeY:Int;

        if (direction > 0)
        {
            edgeY = Std.int(Math.floor(y + object.height - epsilon));
        }
        else
        {
            edgeY = Std.int(Math.floor(y));
        }

        var left = Std.int(Math.floor(x));
        var right = Std.int(Math.ceil(x + object.width)) - 1;

        for (px in left...(right + 1))
        {
            if (solidAt(px, edgeY))
            {
                return true;
            }
        }

        return false;
    }

    public function isGrounded(object:FlxObject, probeDistance:Int = 1):Bool
    {
        return findSupportSurface(object, object.x, object.y + object.height, 1, probeDistance) >= 0;
    }

    public function findGround(x:Float, y:Float, maxDistance:Int):Int
    {
        if (maxDistance < 0)
        {
            return -1;
        }

        var px = Std.int(Math.floor(x));
        var startY = Std.int(Math.floor(y));

        for (offset in 0...(maxDistance + 1))
        {
            var py = startY + offset;

            if (solidAt(px, py))
            {
                return py;
            }
        }

        return -1;
    }

    public function isWall(x:Float, y:Float, height:Float):Bool
    {
        var px = Std.int(Math.floor(x));

        var top = Std.int(Math.floor(y));
        var bottom = Std.int(Math.ceil(y + height)) - 1;

        for (py in top...(bottom + 1))
        {
            if (solidAt(px, py))
            {
                return true;
            }
        }

        return false;
    }

    inline function solidAt(x:Int, y:Int):Bool
    {
        return terrain.isSolidAtWorld(x, y);
    }

    public function canOccupy(x:Float, y:Float, width:Float, height:Float):Bool
    {
        var left = Std.int(Math.floor(x));
        var right = Std.int(Math.ceil(x + width)) - 1;
        var top = Std.int(Math.floor(y));
        var bottom = Std.int(Math.ceil(y + height)) - 1;

        for (py in top...(bottom + 1))
        {
            for (px in left...(right + 1))
            {
                if (solidAt(px, py))
                {
                    return false;
                }
            }
        }

        return true;
    }
}

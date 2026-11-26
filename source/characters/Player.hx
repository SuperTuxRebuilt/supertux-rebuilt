//  Eispinguin
//  Copyright (C) 2026 AnatolyStev
//                2026 Vaesea <sophieballvaesea@proton.me>
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

package characters;

import collision.TerrainPhysics;
import editor.LevelEditorState;
import rebuilt.STRSprite;
import flixel.FlxG;

enum TuxStates
{
    SMALL;
    BIG;
    FIRE;
}

class Player extends STRSprite
{
    // Movement
    public var walkSpeed:Float = 320;
    public var groundAcceleration:Float = 900;
    public var groundDeceleration:Float = 1100;
    public var jumpSpeed:Float = 520;
    public var highJumpSpeed:Float = 580;
    public var jumpCutMultiplier:Float = 0.45;
    var jumpWasHeld:Bool = false;
    var jumpCutApplied:Bool = false;
    var skidThreshold:Float = 200;
    var skidMultiplier:Float = 0.4;

    // Ducking
    var standingHeight:Int = 18;
    var duckingHeight:Int = 11;

    var isDucking:Bool = false;

    // Timers (don't change!)
    var coyoteTimer:Float = 0.0;
    var jumpBufferTimer:Float = 0.0;
    var skidTimer:Float = 0.0;

    // Times
    public var coyoteDuration:Float = 0.15;
    public var jumpBufferDuration:Float = 0.25;
    public var skidDuration:Float = 0.3;

    // Other
    var currentState:TuxStates = SMALL;
    public var direction = 0;

    public function new(x:Float, y:Float, physics:TerrainPhysics)
    {
        super(x, y, physics);

        loadGraphic("assets/images/characters/tux/small_tux.png", true, 57, 48);
        animation.add("stand", [5], 15.0, false);
        animation.add("walk", [0, 1, 2, 3, 4, 5, 6, 7], 15.0, true);
        animation.add("jump", [8], 15.0, false);
        animation.add("kick", [9], 15.0, false);
        animation.add("skid", [10], 15.0, false);

        setSize(28, 31);
        offset.set(15, 17);

        refreshGrounded(2);
    }

    override public function updateMovement(elapsed:Float)
    {
        // Timers below!

        if (skidTimer > 0)
        {
            skidTimer -= elapsed;
        }

        // Kill player if they go below level
        if (y > Global.PS.terrain.height)
        {
            killPlayer();
        }

        // Movement below!

        direction = 0;

        if (!(isDucking && onGround))
        {
            if (FlxG.keys.pressed.LEFT)
            {
                direction = -1;
                flipX = true;
            }

            if (FlxG.keys.pressed.RIGHT)
            {
                direction = 1;
                flipX = false;
            }
        }

        var targetVelocityX = direction * walkSpeed;

        if (isDucking && onGround)
        {
            velocityX = approach(velocityX, 0, groundDeceleration * elapsed);
        }
        else 
        {
            if (direction != 0)
            {
                velocityX = approach(velocityX, targetVelocityX, groundAcceleration * elapsed);
            }
            else
            {
                velocityX = approach(velocityX, 0, groundDeceleration * elapsed);
            }
        }

        var touchingGround = physics.isGrounded(this, 2);

        if (FlxG.keys.pressed.DOWN && touchingGround)
        {
            setDucking(true);
        }
        else if (!FlxG.keys.pressed.DOWN && isDucking)
        {
            setDucking(false);
        }

        touchingGround = physics.isGrounded(this, 2);

        if (touchingGround && ((velocityX > 0 && direction == -1) || (velocityX < 0 && direction == 1)))
        {
            if (Math.abs(velocityX) > skidThreshold)
            {
                velocityX = approach(velocityX, 0, (groundDeceleration * skidMultiplier) * elapsed);

                if (skidTimer <= 0)
                {
                    skidTimer = skidDuration;
                }
            }
        }

        if (touchingGround)
        {
            coyoteTimer = coyoteDuration;
        }
        else if (coyoteTimer > 0)
        {
            coyoteTimer -= elapsed;

            if (coyoteTimer < 0)
            {
                coyoteTimer = 0;
            }
        }

        var jumpHeld = FlxG.keys.pressed.SPACE;

        if (FlxG.keys.justPressed.SPACE)
        {
            jumpBufferTimer = jumpBufferDuration;
        }
        else if (jumpBufferTimer > 0)
        {
            jumpBufferTimer -= elapsed;

            if (jumpBufferTimer < 0)
            {
                jumpBufferTimer = 0;
            }
        }

        if (jumpBufferTimer > 0 && coyoteTimer > 0)
        {
            velocityY = Math.abs(velocityX) > 230 ? -highJumpSpeed : -jumpSpeed;

            jumpBufferTimer = 0;
            coyoteTimer = 0;

            onGround = false;

            jumpCutApplied = false;

            if (!jumpHeld)
            {
                velocityY *= jumpCutMultiplier;
                jumpCutApplied = true;
            }
        }

        if (jumpWasHeld && !jumpHeld && velocityY < 0 && !jumpCutApplied)
        {
            velocityY *= jumpCutMultiplier;

            jumpCutApplied = true;
        }

        jumpWasHeld = jumpHeld;
    }

    override public function updateAfterPhysics(elapsed:Float)
    {
        walkingIntoWall = touchingWall && direction != 0;

        if (onGround)
        {
            coyoteTimer = coyoteDuration;
        }

        animate();
    }

    function animate()
    {
        if (isDucking && currentState != SMALL)
        {
            playAnimation("duck");
            return;
        }

        if (onGround)
        {
            if (skidTimer > 0)
            {
                playAnimation("skid");
            }
            else
            {
                if (velocityX == 0 || walkingIntoWall)
                {
                    playAnimation("stand");
                }
                else if (velocityX != 0 && !walkingIntoWall)
                {
                    playAnimation("walk");
                }
            }
        }
        else
        {
            playAnimation("jump");
        }
    }

    function killPlayer()
    {
        if (Global.PS.editorPlaytest)
        {
            FlxG.switchState(() -> new LevelEditorState(Global.PS.editorLevelPath, Global.PS.editorSavePath, Global.PS.editorPlaytestJson, Global.PS.editorHistory, Global.PS.editorCurrentFilePath));
            return;
        }
        
        FlxG.resetState();
    }

    function setDucking(ducking:Bool)
    {
        if (isDucking == ducking || currentState == SMALL)
        {
            return;
        }

        var feetY = y + height;

        if (ducking)
        {
            setSize(8, duckingHeight);
            offset.set(4, 14);

            y = feetY - duckingHeight;

            isDucking = true;
        }
        else
        {
            var standingY = feetY - standingHeight;

            if (!physics.canOccupy(x, standingY, width, standingHeight))
            {
                return;
            }

            setSize(8, standingHeight);
            offset.set(4, 7);

            y = standingY;

            isDucking = false;
        }
    }
}
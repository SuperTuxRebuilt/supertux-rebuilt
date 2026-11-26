//  Eispinguin
//  Copyright (C) 2026 Vaesea <sophieballvaesea@proton.me>
//                2026 AnatolyStev
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

package states;

import editor.LevelEditorState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class MainMenuState extends FlxState
{
    var menuBox:FlxSprite;
    var logo:FlxSprite;

    var menuItems:FlxTypedGroup<FlxText>;
    var options:Array<String> = [];
    var currentSelected:Int = 0;

    override public function create()
    {
        super.create();

        #if sys
        options = ["Start Game", "Level Editor", "Quit"];
        #else
        options = ["Start Game"];
        #end

        FlxG.timeScale = 1.0;

        if (FlxG.sound.music != null) // Check if song is playing, if it is, stop song. This if statement is here just to avoid a really weird crash
        {
            FlxG.sound.music.stop();
        }

        Global.currentLevel = 0;

        // Adding Main Menu background
        var bg = new FlxSprite();
        bg.loadGraphic("assets/images/background/oiltux.jpg", false);
        add(bg);

        logo = new FlxSprite(0, 75);
        logo.loadGraphic("assets/images/engine/menu/logo.png");
        logo.screenCenter(X);
        add(logo);

        menuBox = new FlxSprite();
        add(menuBox);

        menuItems = new FlxTypedGroup<FlxText>();
        add(menuItems);

        var paddingX:Int = 32;
        var paddingY:Int = 16;
        var itemSpacing:Int = 12;
        var maxWidth:Float = 0;
        var totalHeight:Float = 0;

        for (i in 0...options.length)
        {
            var item = new FlxText(0, 0, 0, options[i], 16);
            item.ID = i;
            menuItems.add(item);

            if (item.width > maxWidth)
            {
                maxWidth = item.width;
            }

            totalHeight += item.height;

            if (i < options.length - 1)
            {
                totalHeight += itemSpacing;
            }
        }

        var boxWidth:Int = Math.ceil(maxWidth + (paddingX * 2));
        var boxHeight:Int = Math.ceil(totalHeight + (paddingY * 2));

        menuBox.makeGraphic(boxWidth, boxHeight, FlxColor.fromRGB(200, 225, 255, 150));
        menuBox.screenCenter(X);
        menuBox.y = (FlxG.height * 0.5) + (menuBox.height * 0.5);

        var currentY:Float = menuBox.y + paddingY;

        menuItems.forEach(function(item:FlxText)
        {
            item.x = (menuBox.x + menuBox.width * 0.5) - item.width * 0.5;
            item.y = currentY;
            currentY += item.height + itemSpacing;
        });

        updateVisuals();
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.UP)
        {
            changeSelection(-1);
        }
        if (FlxG.keys.justPressed.DOWN)
        {
            changeSelection(1);
        }
        if (FlxG.keys.anyJustPressed([ENTER, SPACE]))
        {
            selectOption();
        }

        menuItems.forEach(function(item:FlxText) 
        {
            if (FlxG.mouse.overlaps(item))
            {
                if (FlxG.mouse.justMoved && currentSelected != item.ID)
                {
                    currentSelected = item.ID;
                    updateVisuals();
                }

                if (FlxG.mouse.justPressed)
                {
                    selectOption();
                }
            }
        });
    }

    function changeSelection(change:Int)
    {
        currentSelected += change;

        if (currentSelected < 0)
        {
            currentSelected = options.length - 1;
        }
        if (currentSelected >= options.length)
        {
            currentSelected = 0;
        }

        updateVisuals();
    }

    function updateVisuals()
    {
        menuItems.forEach(function(item:FlxText)
        {
            if (item.ID == currentSelected)
            {
                item.color = 0xFF5F5FFF;
            }
            else
            {
                item.color = FlxColor.WHITE;
            }
        });
    }

    function selectOption()
    {
        #if sys
        switch(currentSelected)
        {
            case 0:
                FlxG.switchState(() -> new PlayState());
            case 1:
                FlxG.switchState(() -> new LevelEditorState("assets/data/levels/blank.json", "levels/level1.json"));
            case 2:
                Sys.exit(0);
        }
        #else
        FlxG.switchState(() -> new PlayState());
        #end
    }
}
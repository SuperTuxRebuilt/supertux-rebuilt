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

package objects;

import editor.LevelEditorState;
import flixel.FlxG;
import flixel.FlxSprite;
import states.MainMenuState;
import states.PlayState;

class Goal extends FlxSprite
{
    public function new(x:Float, y:Float)
    {
        super(x, y);

        loadGraphic("assets/images/objects/goal/portal-snow.png");

        setSize(70, 163);
        offset.set(33, 33);
    }

    public function reach()
    {
        if (!solid)
        {
            return;
        }

        solid = false;

        if (Global.PS.editorPlaytest)
        {
            FlxG.switchState(() -> new LevelEditorState(Global.PS.editorLevelPath, Global.PS.editorSavePath, Global.PS.editorPlaytestJson, Global.PS.editorHistory, Global.PS.editorCurrentFilePath));
            return;
        }

        Global.currentLevel += 1;

        if (Global.currentLevel >= Global.levels.length)
        {
            FlxG.switchState(MainMenuState.new);
        }
        else
        {
            FlxG.switchState(() -> new PlayState());
        }
    }
}
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

package;

import lime.utils.Assets;
import states.PlayState;

class Global
{
    public static var PS:PlayState;

    public static var levels:Array<String>;
    public static var currentLevel = 0;

    public static function loadLevels()
    {
        levels = Assets.getText("assets/data/levels.txt").split("\n").map(StringTools.trim).filter(function(l) return l != "");
    }
}
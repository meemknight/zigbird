const raylib = @import("raylib");
const std = @import("std");
const time = std.time;

const c = @cImport({
     @cInclude("stdio.h");
});

fn loadTexture(file: [*:0] const u8) raylib.Texture2D {
    var img = raylib.LoadImage(file); 
    var t = raylib.LoadTextureFromImage(img); 
    raylib.UnloadImage(img);

    return t;
}

const GameStuff = struct{
    birdPosY : f32 = 0,
    birdVelocityY : f32 = 0,
    birdAdvance : f32 = 0,
    score : i32 = 0,
    pip : [2]Pip = undefined,
};

var gameStuff = GameStuff {};

const h : f32 = 800;
const w : f32 = 600;
const birdSize : f32 = 50;
   
const birdPosX : f32 = 40;

fn intersectBirdWithGround() bool{
    if(gameStuff.birdPosY + birdSize/2.0 > h - 20.0){
        return true;
    }else{
        return false;
    }
}

const pipeGap : f32 = 160;
const pipVelocity : f32 = 100;

pub fn drawAPipe(pipe : raylib.Texture2D, posX : f32, posY : f32) void {

    
    raylib.DrawTexture(pipe, @floatToInt(i32, posX), 
        @floatToInt(i32, posY), raylib.WHITE);

    var topPipePos = posY - pipeGap;

    raylib.DrawTextureEx(pipe, .{.x = posX + @intToFloat(f32, pipe.width), .y = topPipePos}, 180, 1.0, raylib.WHITE);


}

const Pip = struct{
    pos : raylib.Vector2,
    hit : bool = false,
   
};

pub fn setPip(pip : *Pip) void{
    pip.pos.y = @intToFloat(f32, raylib.GetRandomValue(150, h - 150));
    pip.pos.x = w;
    pip.hit = false;
}

fn reset() void {
    gameStuff = GameStuff {};

    setPip(&gameStuff.pip[0]);
    setPip(&gameStuff.pip[1]);
    gameStuff.pip[1].pos.x += 300;
}

fn circleRect(circle : raylib.Vector2, r : f32, rect : raylib.Vector2, rectW : raylib.Vector2) bool
{
    var distance : raylib.Vector2 = undefined;
    distance.x = @fabs(circle.x - rect.x);
    distance.y = @fabs(circle.y - rect.y);
    if (distance.x > (rectW.x/2.0 + r)) { return false; }
    if (distance.y > (rectW.y/2.0 + r)) { return false; }
    if (distance.x <= (rectW.x/2.0)) 
    if (distance.y <= (rectW.y/2.0)) { return true; };
    //var cDist_sq = std.math.pow(f32, (distance.x - rectW.x/2.0), 2) + std.math.pow(f32, (distance.y - rectW.y/2.0), 2);
 
    //return (cDist_sq <= (std.math.pow(f32, r, 2)));
    return false;
}

fn aabb(b1 : raylib.Vector4, b2 : raylib.Vector4) bool
{
	if (((b1.x - b2.x < b2.z)
		and b2.x - b1.x < b1.z
		)
		and ((b1.y - b2.y < b2.w)
		and b2.y - b1.y < b1.w
		)
		)
	{
		return true;
	}
	return false;
}


pub fn main() void {
    raylib.InitWindow(w, h, "flappy gus!");
    raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true });
    raylib.SetTargetFPS(60);

    defer raylib.CloseWindow();

    var bird = loadTexture("amogus.png"); 
    var background = loadTexture("background.png"); 
    var pipe = loadTexture("pipe.png");

    reset();

    var time1 = time.Instant.now() catch unreachable;
    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();
        
        var time2 = time.Instant.now() catch unreachable;

        var deltaTimeNanoseconds= time2.since(time1);

        time1 = time2;

        var deltaTime : f32 = @intToFloat(f32, deltaTimeNanoseconds) * 0.000000001;
        
        gameStuff.birdVelocityY += 10.0 * deltaTime;

        if(gameStuff.birdVelocityY > 5){
            gameStuff.birdVelocityY = 5;
        }

        if (raylib.IsMouseButtonPressed(raylib.MouseButton.MOUSE_BUTTON_LEFT)){
            gameStuff.birdVelocityY = -4;
        }

        gameStuff.birdPosY += gameStuff.birdVelocityY * deltaTime * 60.0;

        if(gameStuff.birdPosY <= 0.0){gameStuff.birdPosY = 0.0;}
        if(gameStuff.birdPosY + birdSize > h - 60.0)
        {
            //gameStuff.birdPosY = h - 60.0 - birdSize;
            reset();
            continue;
        }

        {
            raylib.ClearBackground(raylib.BLACK);
            var backGroundPos : f32 = gameStuff.birdAdvance;
            var intPart = @floatToInt(i32, backGroundPos);
            intPart = @mod(intPart, background.width);
            var finalPos = -intPart;
            raylib.DrawTexture(background, finalPos, 0, raylib.WHITE);
            raylib.DrawTexture(background, finalPos + background.width, 0, raylib.WHITE);
        }

        gameStuff.birdAdvance += deltaTime * pipVelocity;
        
        for(&gameStuff.pip)|*p|{
            p.pos.x -= deltaTime * pipVelocity;


            if(!p.hit and p.pos.x <= birdPosX - @intToFloat(f32, pipe.width)/2.0){
                p.hit = true;
                gameStuff.score += 1;
            }

            if(
                aabb(.{.x = birdPosX, .y = gameStuff.birdPosY, .z = birdSize, .w = birdSize}, 
                .{.x = p.pos.x, .y = p.pos.y, .z = @intToFloat(f32, pipe.width), .w = @intToFloat(f32, pipe.height)})
                or
                 aabb(.{.x = birdPosX, .y = gameStuff.birdPosY, .z = birdSize, .w = birdSize}, 
                .{.x = p.pos.x, .y = p.pos.y - pipeGap - @intToFloat(f32, pipe.height), .z = @intToFloat(f32, pipe.width), .w = @intToFloat(f32, pipe.height)})
            )
            {
                reset();
                continue;
            }

            if(p.pos.x <= - @intToFloat(f32, pipe.width)){ setPip(p); }
            drawAPipe(pipe, p.pos.x, p.pos.y);
        }
       

        raylib.DrawTexturePro(bird, raylib.Rectangle{.x=0,.y=0,.width = 187, .height = 248 }, 
        raylib.Rectangle{.x=birdPosX,.y=gameStuff.birdPosY,.width = birdSize, .height = birdSize }, 
        raylib.Vector2{.x = 0,.y=0}, 0, raylib.WHITE);
        
        
        var buf : [10:0]u8 =  [_:0]u8{0} ** 10;
        _ = std.fmt.bufPrint(&buf, "{}", .{gameStuff.score}) catch unreachable;
        raylib.DrawText(&buf, w/2.0, h/4.0, 50, raylib.WHITE);


        //raylib.DrawFPS(10, 10);

        //raylib.DrawText("hello world!", 100, 100, 20, raylib.YELLOW);
    }
}
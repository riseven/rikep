// Riseven (C) 2009

program rikep; // 4
const 
  MAP_NOTHING = 46;   // .
  MAP_WALL = 35;      // #
  MAP_LEFT = 60;      // <
  MAP_RIGHT = 62;     // >
  MAP_UP = 94;        // ^
  MAP_DOWN = 118;     // v
  MAP_PLAYER = 64;    // @
  MAP_EXIT = 33;      // !
global
  currentLevel;

  backgroundLeft, backgroundTop;

  sizeW;
  sizeH;

  waitMove;
  keyPressed; 
  move; 
  
  map[10000];
  
  playerId;
  
local
  k; 
  destroyed; 
  
begin
  set_mode(800,600,32);
  load_fpg("rikep.fpg");
  play_song(load_song("ro-bott.xm", 1));
  
  startLevel(0);
end

function readCommaEndedNumber(handle) // 4
private
  currentChar, currentNum, number;
begin
  number = 0 ;
  repeat
    currentChar = fgetc(handle);
    if ( currentChar >= 48 && currentChar <= (48 + 9) )
      number = (number * 10) + currentChar - 48;
    end
  until (currentChar == 44);
  return (number);
end

function readMap(handle) // 4
private
  car;
begin
  for ( y = 0 ; y < sizeH ; y++ )
    for ( x = 0 ; x < sizeW ; x++ )
      repeat
        car = fgetc(handle);
        if ( car == 0 )
          fclose(handle);
          exit("Congratulations, you win!", 0);
        end
      until ( car == MAP_NOTHING || car == MAP_WALL || car == MAP_UP || car == MAP_DOWN || 
              car == MAP_LEFT || car == MAP_RIGHT || car == MAP_PLAYER || car == MAP_EXIT )
      map[ y * sizeW + x ] = car ; 
    end
  end
end

function getMapCell(x,y) //1
begin
  return (map[y*sizeW+x]);
end

function setMapCell(x,y,value) //1
begin
  map[y*sizeW+x] = value;
end

process startLevel(numLevel) //13
private
  handle;
  STRING fileName;
begin
  currentLevel = numLevel;

  let_me_alone();
  delete_draw(all_drawing);
  move = 0 ;
  frame;
  
  
  fileName = "level";
  handle = fopen(strcat(strcat(filename,itoa(numLevel+1)),".txt"), "r", "b");
  
  sizeW = readCommaEndedNumber(handle);
  sizeH = readCommaEndedNumber(handle);
  
  readMap(handle);  
  
  fclose(handle);

  Background(handle);

  KeyInput();
end

process Background(handle) // 11
private
  content;
begin
  backgroundLeft = (800 - sizeW*50) / 2;
  backgroundTop = (600 - sizeH*50) /2;
  for ( x = 0 ; x < sizeW ; x++)
    for ( y = 0 ; y < sizeH ; y++ )
      content = map[y*sizeW+x];
      if ( content == MAP_WALL )
        draw(3, rgb(180,180,180), 255, 0, backgroundLeft + x*50, backgroundTop + y*50, backgroundLeft + x*50 + 48, backgroundTop + y*50 + 48);
      else
        draw(3, rgb(0,0,128), 255, 0, backgroundLeft + x*50, backgroundTop + y*50, backgroundLeft + x*50 + 48, backgroundTop + y*50 + 48);
        if ( content == MAP_UP )
          KeyBomb(x,y,_up);
        elseif ( content == MAP_RIGHT)
          KeyBomb(x,y,_right);
        elseif ( content == MAP_DOWN)
          KeyBomb(x,y,_down);
        elseif ( content == MAP_LEFT)
          KeyBomb(x,y,_left);
        elseif ( content == MAP_PLAYER)
          playerId = Player(x,y);
        elseif ( content == MAP_EXIT)
          LevelExit(x,y);
        end
      end
    end
  end
end

process KeyInput() // 8
begin
  waitMove = 0;
  loop
    keyPressed = 0 ;
    if (waitMove > 0 )
      waitMove--;
    else
      if ( key(_down) )
        keyPressed = _down;
      elseif ( key(_up) )
        keyPressed = _up;
      elseif ( key(_left) )
        keyPressed = _left;
      elseif ( key(_right) )
        keyPressed = _right;
      end
    end
    frame;
  end
end

process KeyBomb(x,y,k) // 11
private
  i;
begin
  destroyed = 0;
  KeyBombView(id);
  size = 80;
  loop
    if ( destroyed )
      from i = 255 to 0 step -8;
        alpha = i;
        frame;
      end
      signal(id, s_kill_tree);
    end
    if ( move == k )
      from i = 1 to 4; 
        frame;
      end
      size = 130;
      CrossExplossion(x,y);
    end
    if ( size > 80 )
      size -= 5;
    end
    frame;
  end
end

process Player(x,y) // 16
private
  nx,ny;
  i;
begin
  PlayerView(id);
  destroyed = 0 ;
  
  loop
  
    if ( destroyed )
      from alpha = 255 to 0 step -64;
        frame;
      end
      from i = 1 to 10 step 1;
        frame;
      end
      startLevel(currentLevel);
      signal(id, s_kill);
      frame;
    end 
  
    ny = y + (keyPressed==_down) - (keyPressed==_up);
    nx = x + (keyPressed==_right) - (keyPressed==_left);
    
    if ( canMove(nx,ny,x,y) ) 
      move = keyPressed;      
      push(nx,ny,x,y);
      
      setMapCell(nx,ny,MAP_PLAYER);
      setMapCell(x,y,MAP_NOTHING);
      
      x = nx;
      y = ny;

    end
    
    frame;
  end
end

function push(nx,ny,x,y) // 6
private
  entity,dx,dy,nnx,nny;
begin
  nnx = nx + nx - x;
  nny = ny + ny - y;
  
  while ((entity = get_id(type KeyBomb)))
    if ( entity.x == nx && entity.y == ny )
      if ( getMapCell(nnx,nny) == MAP_NOTHING )
        setMapCell(nnx,nny, getMapCell(nx,ny) );
        setMapCell(nx,ny, MAP_NOTHING);
        entity.x = nnx ;
        entity.y = nny ;
      end
    end
  end
end

function canMove(nx,ny,x,y) // 8
private
  entity,dx,dy,nnx,nny;
begin
  dx = nx-x;
  dy = ny-y;
  nnx = nx+dx;
  nny = ny+dy;
  
  if ( nx < 0 || ny <0 || nx >= sizeW || ny >= sizeH )
    return (false);
  end
  
  if ( getMapCell(nx,ny) == MAP_WALL )
    return (false);
  end
  
  while ( (entity = get_id(type KeyBomb)) )
    if ( entity.x == nx && entity.y == ny )
      if ( nnx < 0 || nny < 0 || nnx >= sizeW || nny >= sizeH || getMapCell(nnx,nny) != MAP_NOTHING )
        return (false);
      end 
    end
  end
  return (true);
end

process LevelExit(x,y) // 5
private
  i;
begin
  LevelExitView(id);
  loop
    frame;
    if ( playerId.x == x && playerId.y == y )
      from size = 130 to 90 step -5;
        frame;
      end
      // Warning: This wait must be greater than the death wait
      // to ensure dead on exit cell
      from i = 1 to 15;
        frame;
      end
      startLevel(currentLevel+1);
    end
  end
end

process LevelExitView(controller) // 7
begin
  graph = 3;
  z = -1000;
  size = 90;
  loop
    x = backgroundLeft + controller.x*50 + 24;
    y = backgroundTop + controller.y*50 + 24;
    size = controller.size;
    frame;
  end
end

process KeyBombView(controller) // 13
private
  dx,dy;
begin
  x = backgroundLeft + controller.x*50 +24;
  y = backgroundTop + controller.y*50 +24;
  z = -1000; 
  size = 80;
  graph = 1;
  angle = (controller.k == _up)*90000 + (controller.k == _left)*180000 + (controller.k == _down)*270000;
  loop
    dx = backgroundLeft + controller.x*50 + 24;
    dy = backgroundTop + controller.y*50 + 24;
  
    size = controller.size;
    alpha = controller.alpha;
    
    x += ((dx > x) - (dx < x))*10;
    y += ((dy > y) - (dy < y))*10;

    
    frame;
  end
end

process PlayerView(controller) // 12
private
  dx,dy;
begin
  x = backgroundLeft + controller.x*50 + 24;
  y = backgroundTop + controller.y*50 + 24;
  z = -1000;
  size = 90;
  graph = 2;
  loop
    dx = backgroundLeft + controller.x*50 + 24;
    dy = backgroundTop + controller.y*50 + 24;
    alpha = controller.alpha;

    if ( waitMove < 5 * (dx>x || dx<x || dy>y || dy<y) )
      waitMove = 2 * (dx>x || dx<x || dy>y || dy<y);
    end

    x += ((dx > x) - (dx < x))*10;
    y += ((dy > y) - (dy < y))*10;
    
    frame;
  end
end

process CrossExplossion(x,y) //24
private
  left,top,right,bottom;
  hrect, vrect;
  a;
  entity;
  px,py;
begin
  left = top = 0;
  right = sizeW;
  bottom = sizeH;
  
  // horizontal limits
  for ( px = x ; px >= 0 ; px-- )
    if ( getMapCell(px,y) == MAP_WALL )
      break;
    end
    left = px;
  end
  
  for ( px = x ; px < sizeW ; px++ )
    if ( getMapCell(px,y) == MAP_WALL )
      break;
    end
    right = px+1;
  end
  
  // vertical limits
  for ( py = y ; py >= 0 ; py-- )
    if ( getMapCell(x,py) == MAP_WALL )
      break;
    end
    top = py;
  end
  
  for ( py = y ; py < sizeH ; py++ )
    if ( getMapCell(x,py) == MAP_WALL )
      break;
    end
    bottom = py+1;
  end
  
  hrect = draw(3,rgb(0,255,0),255,0,
    backgroundLeft+left*50+5,
    backgroundTop+y*50+20,
    backgroundLeft+right*50-5,
    backgroundTop+y*50+30);
  vrect = draw(3,rgb(0,255,0),255,0,
    backgroundLeft+x*50+20,
    backgroundTop+top*50+5,
    backgroundLeft+x*50+30,
    backgroundTop+bottom*50-5);
  lock_draw(hrect);
  lock_draw(vrect);
  
  frame;
  
  // Destroying
  while ( (entity=get_id(type KeyBomb)) )
    if ( ((entity.x == x && entity.y >= top && entity.y < bottom) || 
          (entity.y == y && entity.x >= left && entity.x < right)) && entity.k != father.k )
      entity.destroyed = 1;
      setMapCell(entity.x,entity.y,MAP_NOTHING);
    end
  end
  
  if ( (playerId.x == x && playerId.y >= top && playerId.y < bottom) ||
       (playerId.y == y && playerId.x >= left && playerId.x < right) )
    playerId.destroyed = 1;
  end
  
  from a = 255 to 0 step -16;
    set_draw_alpha(hrect, a);
    set_draw_alpha(vrect, a);
    frame;
  end
  delete_draw(hrect);
  delete_draw(vrect);
end


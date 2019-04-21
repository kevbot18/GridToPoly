Point[] bench = new Point[0];

void setup() {
    size(640, 640);
    fill(255);



    for (int i = 0; i < bench.length; i++) {
        bench[i] = new Point(random(WIDTH), random(HEIGHT));
    }

    println("Press \"b\" to start benchmark");
}

final int SIZE = 16;
final int WIDTH = 640;
final int HEIGHT = 640;


// debug shows all points, toggle with ` (above tab)
boolean debug = false;
// full_debug shows all lines that aren't blocked, toggle with ~ (above tab, hold shift)
boolean full_debug = false;
// fills visibile area, toggle with TAB
boolean fillVisibility = true;

// grid object
Grid grid = new Grid(WIDTH / SIZE, HEIGHT / SIZE, SIZE);
// Holds list of lines and verticies
PolygonMap map = new PolygonMap(grid);
// fill cells, toggle with SPACE
boolean showCells = true;
// whether or not to regenrate PolygonMap's lines and verticies
boolean change = true;

// What "emits light" or "can see", hold z to follow mouse
Point player = new Point(WIDTH / 2, HEIGHT / 2);

void perfTestMoveRandomly(Point[] points) {
    for (Point p : points) {
        float px = p.x;
        float py = p.y;
        p.x += 1.0;
        p.y += 1.0;

        if (p.x > WIDTH) {
            p.x = 0;
            p.y = random(HEIGHT);
        }
        if (p.y > HEIGHT) {
            p.x = random(WIDTH);
            p.y = 0;
        }
    }
}

// calculate frametime
float frameTime = 0;

// set to true when z is pressed
boolean moveWithMouse = false;

// player WASD controls
boolean up = false;
boolean down = false;
boolean left = false;
boolean right = false;

float fps = 0;
int below = 0;

// time it is going too slow
float redFrame = 0;
float blueFrame = 0;

boolean benchmark = false;
int benchMode = 0;
float startTime = 0;

void draw() {

    if (moveWithMouse) {
        player.x = mouseX;
        player.y = mouseY;
    }

    if (up) {
        player.y -= 2;
    }
    if (down) {
        player.y += 2;
    }
    if (left) {
        player.x -= 2;
    }
    if (right) {
        player.x += 2;
    }

    // if the grid has changed, recalculate all points and edges
    if (change) {
        map.generate(grid);
        map.getPoints();
        change = false;
        blueFrame = 0;
        redFrame = 0;
    }
    // clears screen
    background(0);

    if (benchmark) {
        player.x = random(WIDTH);
        player.y = random(HEIGHT);
    }

    perfTestMoveRandomly(bench);


    if (benchmark) {
        // fills with black or there's TONS of flashing
        // DO NOT REMOVE THIS
        fill(0);
        stroke(0);
    } else {
        fill(255);
        stroke(255);
    }
    // bulk of program, finds what is visible
    drawVisibilityMap(map.lines, map.points, player);

    fill(255);
    stroke(255);
    for (Point p : bench) {
        drawVisibilityMap(map.lines, map.points, p);
    }

    // show cells or not
    if (showCells) {
        strokeWeight(0);
        stroke(255);
        grid.draw();
    }

    stroke(0, 0, 255);
    strokeWeight(2);

    map.draw();
    if (debug) {
        // used to make sure all vertecies are being created
        stroke(0, 255, 0);
        map.drawPoints();
    }

    stroke(255, 255, 0);
    strokeWeight(6);
    player.draw();
    for (Point p : bench) {
        p.draw();
    }

    // Performance info
    fill(0, 100, 100, 200);
    noStroke();
    rect(6, 2, 80, 60);
    fill(255);
    text("Lines:   " + map.lines.size(), 10, 12);
    text("Points:  " + map.points.length, 10, 24);
    text("Players: " + (1 + bench.length), 10, 36);
    fps = 1000.0 / (millis()-frameTime);

    if (fps < 60) {
        below ++;
    } else {
        below = 0;
    }
    // allows for variance in framerate
    // if 5 consecutive frames are below 60, then it's going too slow
    if (below > 5) {
        redFrame ++;
        fill(255, 0, 0);
    } else if (below == 5) {
        redFrame = 5;
        blueFrame -= 5;
        if (blueFrame < 0) {
            redFrame -= blueFrame;
            blueFrame = 0;
        }
    } else {
        blueFrame ++;
    }
    text("FPS: " + fps, 10, 48);
    text("Ratio: " + round(redFrame / (redFrame + blueFrame) * 100) + "%", 10, 60);
    frameTime = millis();

    if (benchmark) {
        if (millis() - startTime > 3000) {
            if (redFrame / (redFrame + blueFrame) <= 0.1) {
                changeBench(1); // horrible name, increases number of entities
                startTime = millis();
            } else {
                // max is one below current total
                println("Mode: " + benchMode + " Max Objects: " + (bench.length));
                if (benchMode < 3) {
                    benchMode++;
                    changeBench(-bench.length);
                    if (benchMode == 1) {
                        alternatePattern(false);
                    } else if (benchMode == 2) {
                        spacedAlternate(false);
                    } else if (benchMode == 3) {
                        randomFill();
                    }
                    startTime = millis();
                } else {
                    benchmark = false;
                    println("Benchmark Finished");
                }
            }
        }
    }
}

void mousePressed() {
    // changes state of cells in grid
    grid.mouseSet(mouseButton == LEFT);
    change = true;
}

void mouseDragged() {
    // changes state of cells in grid
    grid.mouseSet(mouseButton == LEFT);
    change = true;
}

void mouseReleased() {
    change = true;
}

void changeBench(int amount) {
    if (bench.length + amount >= 0) {
        Point[] tmp = new Point[bench.length + amount];
        for (int i = 0; i < bench.length && i < bench.length + amount; i++) {
            tmp[i] = bench[i];
        }
        for (int i = bench.length; i < tmp.length; i++) {
            tmp[i] = new Point(random(WIDTH), random(HEIGHT));
        }
        bench = tmp;
        change = true;
    }
}

void alternatePattern(boolean invert) {
    if (!invert) {
        for (int y = 0; y < grid.HEIGHT; y++) {
            for (int x = 0; x < grid.WIDTH; x++) {
                int index = x + y * grid.WIDTH;
                grid.cells[index] = (x % 2 == 0) && (y % 2 == 0);
            }
        }
    } else {
        for (int y = 0; y < grid.HEIGHT; y++) {
            for (int x = 0; x < grid.WIDTH; x++) {
                int index = x + y * grid.WIDTH;
                grid.cells[index] = (x % 2 == 1) || (y % 2 == 1);
            }
        }
    }
    change = true;
}

void spacedAlternate(boolean invert) {
    if (!invert) {
        for (int y = 0; y < grid.HEIGHT; y++) {
            for (int x = 0; x < grid.WIDTH; x++) {
                int index = x + y * grid.WIDTH;
                grid.cells[index] = ((x/2 % 2 == 0) ^ (y/2 % 2 == 0)) && x % 2 == 0 && y % 2 == 0;
            }
        }
    } else {
        for (int y = 0; y < grid.HEIGHT; y++) {
            for (int x = 0; x < grid.WIDTH; x++) {
                int index = x + y * grid.WIDTH;
                grid.cells[index] = ((x/2 % 2 == 1) ^ (y/2 % 2 == 1)) && x % 2 == 1 && y % 2 == 1;
            }
        }
    }
    change = true;
}

void randomFill() {
    for (int y = 0; y < grid.HEIGHT; y++) {
        for (int x = 0; x < grid.WIDTH; x++) {
            int index = x + y * grid.WIDTH;
            grid.cells[index] = Math.random() > 0.8;
        }
    }
    change = true;
}

void setGrid(boolean state) {
    for (int i = 0; i < grid.HEIGHT * grid.WIDTH; i++) {
        grid.cells[i] = state;
    }
    change = true;
}

void keyPressed() {
    // a bunch of key bindings
    // ^= true toggles a boolean

    if (key == ' ') { // Fill in cells or not
        showCells ^= true;
        change = true;
    } else if (key == '1') { // Cell pattern
        alternatePattern(false);
    } else if (key == '!') { // Inverse Cell pattern
        alternatePattern(true);
    } else if (key == 'c') { // Clears cells
        setGrid(false);
    } else if (key == 'C') { // Fills all cells
        setGrid(true);
    } else if (key == '2') { // Cell pattern
        spacedAlternate(false);
    } else if (key == '@') { // Inverse Cell pattern
        spacedAlternate(true);
    } else if (key == 'r') {
        randomFill();
    } else if (key == '[') {
        changeBench(-1);
    } else if (key == ']') {
        changeBench(1);
    }


    if (key == '3' || key == '#') { // Inverts all cells
        for (int i = 0; i < grid.HEIGHT * grid.WIDTH; i++) {
            grid.cells[i] ^= true;
        }
        change = true;
    }
    if (key == '~') { // shows line to player from all visible verticies
        full_debug ^= true;
    }
    if (key == '`') { // shows all points (verticies) found
        debug ^= true;
    }

    if (key == 'b' || key == 'B') { // benchmark mode
        benchmark ^= true;
        if (benchmark) {
            println("Starting Benchmark");
            benchMode = 0;
            debug = false;
            full_debug = false;
            showCells = true;
            fillVisibility = true;
            setGrid(false);
            startTime = millis();
        }
    }

    if (key == 'w' || keyCode == UP) {
        up = true;
    }
    if (key == 's' || keyCode == DOWN) {
        down = true;
    }

    if (key == 'a' || keyCode == LEFT) {
        left = true;
    }
    if (key == 'd' || keyCode == RIGHT) {
        right = true;
    }

    if (key == 'z') {
        moveWithMouse = true;
    }

    if (key == '\t') {
        fillVisibility ^= true;
    }
}

void keyReleased() {
    if (key == 'z') {
        moveWithMouse = false;
    }
    if (key == 'w' || keyCode == UP) {
        up = false;
    }
    if (key == 's' || keyCode == DOWN) {
        down = false;
    }

    if (key == 'a' || keyCode == LEFT) {
        left = false;
    }
    if (key == 'd' || keyCode == RIGHT) {
        right = false;
    }
}

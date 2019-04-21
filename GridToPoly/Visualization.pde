/*
Test implementation of a Line-Of-Sight algorithm.
 Current limmitations:
 - Performance: this implementation is very inefficient.
 For every point in the scene, a ray is "cast" from the source to every vertex in the scene which involves going through every line in the scene to test for collision. This happens on every frame.
 - Needs Borders: This implementation requires a line intersection for light to be cast
 This implementation uses intersection points of line segments to calculate which regions are illuminated. If there is no border then there will be no intersection and thus incorrect lighting.
 - Probably More
 
 */

// A sorted set that removes duplicates
// this helps reduce the number of points created
import java.util.TreeSet;

// final int SIZE = 16;
// final int WIDTH = 640;
// final int HEIGHT = 640;

/** Class that contains a simple boolean array.
 * This is what stores and draws the grid.
 * It is read by PolygonMap to be used for ray-casting
 * @see PolygonMap
 */
private class Grid {
    boolean[] cells;
    final int HEIGHT;
    final int WIDTH;
    final int SIZE;

    // Creates a new Grid object setting its size using passed in width, height, and size values
    Grid(int width, int height, int size) {
        HEIGHT = height;
        WIDTH = width;
        SIZE = size;
        cells = new boolean[WIDTH*HEIGHT];
    }

    // Simple method that avoids any issues with out-of-bounds access
    boolean get(int x, int y) {
        if (x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT) {
            return cells[x + y * WIDTH];
        }
        return false;
    }

    // Goes through each element in the array and draws a square if it is present
    void draw() {
        fill(151);
        int i = 0;
        for (int y = 0; y < HEIGHT; y++) {
            for (int x = 0; x < WIDTH; x++) {
                if (cells[y*WIDTH + x]) {
                    rect(x * SIZE, y*SIZE, SIZE, SIZE);
                    i++;
                }
            }
        }
    }

    void mouseSet(boolean cell) {
        int x = mouseX / SIZE;
        int y = mouseY / SIZE;
        if (x < WIDTH && y < HEIGHT && x >= 0 && y >= 0) {
            cells[x + y*WIDTH] = cell;
        }
    }
}

public class Point implements Comparable<Point> {
    float x;
    float y;

    Point(float x, float y) {
        this.x = x;
        this.y = y;
    }

    boolean equals(Point p) {
        return p != null && (this.x == p.x && this.y == p.y);
    }

    boolean equals(Point p, float err) {
        return p != null && (abs(this.x-p.x) < err && abs(this.y - p.y) < err);
    }

    float dist2(Point p) {
        return sq(this.x - p.x) + sq(this.y - p.y);
    }

    int compareTo(Point p) {
        if (this.equals(p)) {
            return 0;
        } else {
            if (this.x != p.x) {
                if (this.x > p.x) {
                    return 2;
                } else {
                    return -2;
                }
            } else {
                if (this.y > p.y) {
                    return 1;
                } else {
                    return -1;
                }
            }
        }
    }

    void draw() {
        ellipse(x, y, 3, 3);
    }
}

// Holds two points to define a line
// used in this code as start end end points of line segments
private class Line implements Comparable<Line> {
    Point start;
    Point end;
    float slope;

    Line(float x1, float y1, float x2, float y2) {
        start = new Point(x1, y1);
        end = new Point(x2, y2);
        slope = atan2(end.y - start.y, end.x - start.x);
    }

    // Constructor that sets the slope, allowing the slope to be set relative to another object
    Line(float x1, float y1, float x2, float y2, float slope) {
        this.start = new Point(x1, y1);
        this.end = new Point(x2, y2);
        this.slope = slope;
    }

    boolean equals(Line l2) {
        return compareTo(l2) == 0;
    }

    int compareTo(Line l2) {
        if (slope == l2.slope) {
            return 0;
        } else {
            if (slope > l2.slope) {
                return 1;
            } else {
                return -1;
            }
        }
    }

    void setEnd(float x, float y) {
        this.end.x = x;
        this.end.y = y;
        slope = atan2(end.y - start.y, end.x - start.x);
    }

    void setStart(float x, float y) {
        this.start.x = x;
        this.start.y = y;
        slope = atan2(end.y - start.y, end.x - start.x);
    }

    void set(float x1, float y1, float x2, float y2) {
        setStart(x1, y1);
        setEnd(x2, y2);
    }

    void draw() {
        line(start.x, start.y, end.x, end.y);
    }
}

// Class used to convert Grid into points and lines to calculate the visibility polygons
private class PolygonMap {

    ArrayList<Line> lines;
    Point[] points;

    PolygonMap() {
        lines = new ArrayList<Line>();
        points = null;
    }

    PolygonMap(Grid tilemap) {
        this();
        generate(tilemap);
    }

    // Calculates all edges and vertecies given a Grid
    // Not too worried about performance here as this is only done on Grid change, not every frame
    void generate(Grid tilemap) { 
        float scale = tilemap.SIZE;
        int width = tilemap.WIDTH;
        int height = tilemap.HEIGHT;

        int[] topEdge = new int[width * height];
        int[] leftEdge = new int[width * height];
        for (int i = 0; i < width * height; i++) {
            topEdge[i] = -1;
            leftEdge[i] = -1;
        }

        lines.clear();

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int index = x + y * width;
                int topIndex = -1;
                int leftIndex = -1;
                boolean top = tilemap.get(x, y-1);
                boolean left = tilemap.get(x-1, y);

                if (x > 0) {
                    leftIndex = leftEdge[(x-1)+y*width];
                }
                if (y > 0) {
                    topIndex = topEdge[x+(y-1)*width];
                }

                // Check for Top and Left neighbors (created Top Left to Bottom Right)
                if (tilemap.get(x, y)) {
                    if (!left && x != 0) {
                        if (topIndex != -1) {
                            lines.get(topIndex).setEnd(x * scale, (y+1.0)*scale);
                            topEdge[index] = topIndex;
                        } else {
                            topEdge[index] = lines.size();
                            lines.add(new Line(x * scale, y * scale, x *scale, (y+1.0)*scale));
                        }
                    }

                    if (!top && y != 0) {
                        if (leftIndex != -1) {
                            lines.get(leftIndex).setEnd((x+1.0) * scale, y*scale);
                            leftEdge[index] = leftIndex;
                        } else {
                            leftEdge[index] = lines.size();
                            lines.add(new Line(x * scale, y * scale, (x+1.0) *scale, y*scale));
                        }
                    }
                } else {
                    if (top) {
                        if (leftIndex == -1) {
                            leftEdge[index] = lines.size();
                            lines.add(new Line(x * scale, y * scale, (x+1.0) *scale, y*scale));
                        } else {
                            leftEdge[index] = leftIndex;
                            lines.get(leftIndex).setEnd((x+1.0) * scale, y*scale);
                        }
                    }

                    if (left) {
                        if (topIndex == -1) {
                            topEdge[index] = lines.size();
                            lines.add(new Line(x * scale, y * scale, x *scale, (y+1.0)*scale));
                        } else {
                            topEdge[index] = topIndex;
                            lines.get(topIndex).setEnd(x * scale, (y+1.0)*scale);
                        }
                    }
                }
            }
        }

        // add bounds
        // the algorithm needs an outer bound to correctly create visible region

        // top
        lines.add(new Line(0, 0, WIDTH, 0));
        // bottom
        lines.add(new Line(0, HEIGHT, WIDTH, HEIGHT));
        // left
        lines.add(new Line(0, 0, 0, HEIGHT));
        // right
        lines.add(new Line(WIDTH, 0, WIDTH, HEIGHT));
    }

    // Calculates and converts TreeSet of points into ordered array of points for faster lookup
    void getPoints() {

        TreeSet<Point> tPoint = new TreeSet();
        for (Line l : lines) {
            tPoint.add(l.start);
            tPoint.add(l.end);
            // ArrayList of lines produces the minimum number of lines
            // This makes sure it creates the necessary points where the lines cross
            for (Line n : lines) {
                if (l != n) {
                    Point intersect = checkIntersection(l, n);
                    if (intersect != null) {
                        tPoint.add(intersect);
                    }
                }
            }
        }
        points = new Point[tPoint.size()];
        points = tPoint.toArray(points);
    }

    void drawPoints() {
        for (Point p : points) {
            p.draw();
        }
    }

    void drawLinesFrom(Point origin) {
        for (Point p : points) {
            line(origin.x, origin.y, p.x, p.y);
        }
    }

    void draw() {
        for (Line l : lines) {
            l.draw();
        }
    }
}

// from https://stackoverflow.com/a/1968345
Point checkIntersection(Line l1, Line l2) {

    // calculate the delta x and y of both line segments
    float s1_x, s1_y, s2_x, s2_y;
    s1_x = l1.end.x - l1.start.x;
    s1_y = l1.end.y - l1.start.y;
    s2_x = l2.end.x - l2.start.x;
    s2_y = l2.end.y - l2.start.y;

    // TODO: figure out what determinant is
    float determinant = (-s2_x * s1_y + s1_x * s2_y);

    float s, t;
    // s is normalized (0 being start, 1 being end) length of line l2
    s = (-s1_y * (l1.start.x - l2.start.x) + s1_x * (l1.start.y - l2.start.y)) / determinant;
    // t is normalized length of line l1
    t = ( s2_x * (l1.start.y - l2.start.y) - s2_y * (l1.start.x - l2.start.x)) / determinant;
    if ( s >= 0 && s <= 1 && t >= 0 && t <= 1) {
        // if 0 <= t <= 1 and 0 <= s <= 1 then the line segments intersect
        // if they are less than 0 or greater than 1 then the lines intersect, just not the segments
        float x = l1.start.x + (t * s1_x);
        float y = l1.start.y + (t * s1_y);
        return new Point(x, y);
    } else {
        // line segments do not intersect, returns null
        return null;
    }
}

// Similar to checkIntersection
PointAngle rayIntersection(float s1x1, float s1y1, float s1x2, float s1y2, float s2x1, float s2y1, float s2x2, float s2y2) {

    float s1_x, s1_y, s2_x, s2_y;
    s1_x = s1x2 - s1x1;
    s1_y = s1y2 - s1y1;
    s2_x = s2x2 - s2x1;
    s2_y = s2y2 - s2y1;

    float determinant = (-s2_x * s1_y + s1_x * s2_y);

    float s, t;
    s = (-s1_y * (s1x1 - s2x1) + s1_x * (s1y1 - s2y1)) / determinant;
    t = ( s2_x * (s1y1 - s2y1) - s2_y * (s1x1 - s2x1)) / determinant;
    if ( s >= 0 && s <= 1 && t >= 0) {
        // as long as t is not negative then the intersection occurs on the array
        // if negative then the lines intersect, just behind the array
        float x = s1x1 + (t * s1_x);
        float y = s1y1 + (t * s1_y);
        return new PointAngle(x, y, t);
    } else {
        return null;
    }
}

// Very similar to Point just with an angle float.
// Used for sorting the points by angle for proper construction of the visibliity polygon
class PointAngle implements Comparable<PointAngle> {
    float angle;
    float x;
    float y;

    public PointAngle(float x, float y, float a) {
        this.angle = a;
        this.x = x;
        this.y = y;
    }

    int compareTo(PointAngle p) {
        if (this == p) {
            return 0;
        } else if (angle == p.angle) {
            return 0;
        } else if (angle > p.angle) {
            return 1;
        } else {
            return -1;
        }
    }
}

// Calculates and draws the vivible regions from the point
void drawVisibilityMap(ArrayList<Line> lines, Point[] verts, Point origin) {
    Point intersect = null;
    Line sight = null;
    boolean occluded;

    // set full_debug stuff outside of loops
    // shows line from all verticies to origin (all tested intersections)
    if (full_debug) {
        noFill();
        strokeWeight(1);
    }
    if (!fillVisibility) {
        strokeWeight(1);
    }

    // TreeSet keeps a sorted set without duplicates
    // Ran into issue using arraylist and sorting with Collectsions.sort()
    // TreeSet sorts PointAngle by their angle, which allows for correct
    // construction of visibility polygon
    TreeSet<PointAngle> fanSegments = new TreeSet<PointAngle>();
    for (Point p : verts) {
        PointAngle cross = null;
        sight = new Line(origin.x, origin.y, p.x, p.y);
        occluded = false;

        // Just check if the vertex is visible
        // if not, stop immediately and go to next line
        for (Line l : lines) {
            intersect = checkIntersection(sight, l);
            if (intersect != null && !intersect.equals(p) ) {
                // this point is blocked, continue to next point
                occluded = true;
                break;
            }
        }

        if (full_debug) {
            if (occluded) {
                stroke(200, 50, 50);
            } else {
                stroke(50, 200, 50);
            }
            line(sight.start.x, sight.start.y, sight.end.x, sight.end.y);
        }

        // if the vertex is visible, find first point on line it blocks
        // and add that to points for visbibility polygon
        if (!occluded) {
            // calculate the angle from the source to the vertex
            float angle = atan2(sight.end.y - origin.y, sight.end.x - origin.x);
            float offset = 0.0001;
            // get slight offsets from vertex
            // uses rayIntersection() so ray can be any length (not negative)
            float xOff1 = sight.start.x + cos(angle - offset);
            float yOff1 = sight.start.y + sin(angle - offset);
            float xOff2 = sight.start.x + cos(angle + offset);
            float yOff2 = sight.start.y + sin(angle + offset);

            // Store the closest point
            PointAngle closest = new PointAngle(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY);

            // Just left of point (counterclockwise)
            closest = new PointAngle(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY);
            // Loop over every line checking for intersections
            for (Line l : lines) {
                // check for intersection with current line
                cross = rayIntersection(sight.start.x, sight.start.y, xOff1, yOff1, l.start.x, l.start.y, l.end.x, l.end.y);
                // if there is an intersection (cross is assigned a value) then
                // check if it is shorter than the current closest point
                // using PointAngle's angle field to store location
                // actual angle is calculated later
                if (cross != null && cross.compareTo(closest) < 1) {
                    closest = cross;
                }
            }

            // Check if there actually was an intersection, if not, then skip
            if (closest.x != Float.POSITIVE_INFINITY && closest.y != Float.POSITIVE_INFINITY) {
                // set the angle to the point from the origin
                closest.angle = atan2(closest.y - origin.y, closest.x - origin.x);
                // add closest point (first to be blocked) to fan segment
                fanSegments.add(closest);
            }


            // Same as above
            // Just right of point (clockwise)
            closest = new PointAngle(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY);
            // Loop over every line checking for intersections
            for (Line l : lines) {
                // check for intersection with current line
                cross = rayIntersection(sight.start.x, sight.start.y, xOff2, yOff2, l.start.x, l.start.y, l.end.x, l.end.y);
                // if there is an intersection (cross is assigned a value) then
                // check if it is shorter than the current closest point
                // using PointAngle's angle field to store location
                // actual angle is calculated later
                if (cross != null && cross.compareTo(closest) < 1) {
                    closest = cross;
                }
            }

            // Check if there actually was an intersection, if not, then skip
            if (closest.x != Float.POSITIVE_INFINITY && closest.y != Float.POSITIVE_INFINITY) {
                closest.angle = atan2(closest.y - origin.y, closest.x - origin.x);
                // add closest point (first to be blocked) to fan segment
                fanSegments.add(closest);
            }

            // add the vertex to the fan segment set
            fanSegments.add(new PointAngle(p.x, p.y, atan2(p.y - origin.y, p.x - origin.x)));
        }
    }

    // only loop if there actually are any fan segments
    if (fanSegments.size() > 1) {
        if (fillVisibility) {
            noStroke();
            // fill(255);
        } else {
            noFill();
             stroke(255);
        }
        beginShape();
        for (PointAngle p : fanSegments) {
            vertex(p.x, p.y);
        }
        endShape();
    }
}

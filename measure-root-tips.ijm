// ================================================================
// Root Tip Width Measurement Macro  v2  (Fiji / ImageJ 1.53t+)
// ================================================================
// CHANGE FROM v1:
//   Detection is now GRADIENT-based by default — it finds where
//   intensity changes fastest (the rim), not where it's darkest
//   (which can be an internal stained cell wall). Switch with the
//   DETECTION_METHOD parameter if a particular image needs it.
//
// HOW TO USE (per image)
//   1. Analyze → Set Scale  (use your 1 mm ruler; Unit: mm)
//   2. Pick the straight-line tool.
//   3. Click at the root tip, drag 2.00 mm down the centerline.
//   4. Run this macro.
//   5. Inspect the cyan segments. Yes = log; No = skip & re-draw.
// ================================================================

// ---- ADJUSTABLE PARAMETERS ----
DETECTION_METHOD    = "gradient";   // "gradient" | "threshold" | "darkest"
NUM_POINTS          = 8;
POINT_SPACING_MM    = 0.25;
SEARCH_HALFWIDTH_MM = 0.80;         // perpendicular search radius
MIN_EDGE_DIST_MM    = 0.03;         // ignore edges inside this radius
PROFILE_LINEWIDTH   = 5;            // px averaged along profile
SMOOTH_WINDOW       = 5;            // profile moving-average (odd int)
DERIV_SMOOTH_WINDOW = 7;            // derivative smoothing (gradient mode)
BLUR_SIGMA          = 1.0;          // Gaussian blur on working image
EDGE_FRACTION       = 0.45;         // threshold-mode: 0=bg, 1=darkest
CONFIRM_BEFORE_LOG  = true;
TABLE_NAME          = "RootTipWidths";

// ================================================================
// --- DO NOT EDIT BELOW THIS LINE ---
// ================================================================

if (nImages == 0) exit("Open your root tip image first.");
if (selectionType() != 5)
    exit("Draw a STRAIGHT LINE selection (2.00 mm long) from the\n"
       + "root tip down the centerline, then run the macro again.");
getPixelSize(unit, pw, ph);
if (unit != "mm") {
    showMessageWithCancel("Scale unit not mm",
        "The current scale unit is '" + unit + "', not 'mm'.\n"
      + "Use Analyze → Set Scale and set 'Unit of length' to mm\n"
      + "BEFORE running this macro.\n\n"
      + "OK = continue with current scale, Cancel = stop.");
}

getLine(cx1, cy1, cx2, cy2, curLW);
dX = cx2 - cx1;  dY = cy2 - cy1;
lenPx = sqrt(dX*dX + dY*dY);
if (lenPx < 4) exit("Centerline is too short.");
lenMM = lenPx * pw;
if (abs(lenMM - NUM_POINTS*POINT_SPACING_MM) > 0.20) {
    if (!getBoolean("Centerline is " + d2s(lenMM,3)
        + " mm, expected " + (NUM_POINTS*POINT_SPACING_MM)
        + " mm.\nContinue anyway?")) exit();
}
ux = dX / lenPx;  uy = dY / lenPx;
nx = -uy;         ny =  ux;
halfPx    = SEARCH_HALFWIDTH_MM / pw;
minEdgePx = MIN_EDGE_DIST_MM    / pw;

// --- grayscale working image (purple rim = darkest) ---
origTitle = getTitle();
origID    = getImageID();
run("Select None");
run("Duplicate...", "title=__rtw_src");
if (bitDepth() == 24) {
    run("Split Channels");
    selectWindow("__rtw_src (red)");   close();
    selectWindow("__rtw_src (blue)");  close();
    selectWindow("__rtw_src (green)"); rename("__rtw_work");
} else {
    rename("__rtw_work");
}
run("Gaussian Blur...", "sigma=" + BLUR_SIGMA);
workID = getImageID();

// --- measurement loop ---
distArr  = newArray(NUM_POINTS);
widthArr = newArray(NUM_POINTS);
ex1Arr   = newArray(NUM_POINTS);  ey1Arr = newArray(NUM_POINTS);
ex2Arr   = newArray(NUM_POINTS);  ey2Arr = newArray(NUM_POINTS);

run("Line Width...", "line=" + PROFILE_LINEWIDTH);

for (i = 0; i < NUM_POINTS; i++) {
    d_mm = (i + 1) * POINT_SPACING_MM;
    d_px = d_mm / pw;
    px = cx1 + ux * d_px;  py = cy1 + uy * d_px;
    ax = px - nx * halfPx; ay = py - ny * halfPx;
    bx = px + nx * halfPx; by = py + ny * halfPx;

    selectImage(workID);
    makeLine(ax, ay, bx, by);
    raw    = getProfile();
    nProf  = raw.length;
    profSm = smoothArray(raw, SMOOTH_WINDOW);
    cIdx    = floor((nProf - 1) / 2);
    exclude = round(minEdgePx * nProf / (2 * halfPx));
    if (exclude < 1) exclude = 1;

    idxA = -1;  idxB = -1;

    if (DETECTION_METHOD == "gradient") {
        // smoothed first derivative
        deriv = newArray(nProf);
        deriv[0] = 0;
        for (k = 1; k < nProf; k++) deriv[k] = profSm[k] - profSm[k-1];
        derivSm = smoothArray(deriv, DERIV_SMOOTH_WINDOW);
        // side A: steepest DROP (bg -> tissue) — most negative derivative
        minDer = 1e30;
        for (k = 1; k <= cIdx - exclude; k++)
            if (derivSm[k] < minDer) { minDer = derivSm[k]; idxA = k; }
        // side B: steepest RISE (tissue -> bg) — most positive derivative
        maxDer = -1e30;
        for (k = cIdx + exclude; k < nProf; k++)
            if (derivSm[k] > maxDer) { maxDer = derivSm[k]; idxB = k; }
    }
    else if (DETECTION_METHOD == "threshold") {
        // adaptive threshold between profile's bg (high) and darkest (low)
        sorted = Array.copy(profSm);
        Array.sort(sorted);
        nS = sorted.length;
        pLow  = sorted[floor(nS * 0.10)];
        pHigh = sorted[floor(nS * 0.90)];
        thr = pHigh - EDGE_FRACTION * (pHigh - pLow);
        // side A: first k from 0 inward where profile dips below threshold
        for (k = 0; k <= cIdx - exclude; k++)
            if (profSm[k] < thr) { idxA = k; break; }
        // side B: first k from nProf-1 inward where profile dips below threshold
        for (k = nProf - 1; k >= cIdx + exclude; k--)
            if (profSm[k] < thr) { idxB = k; break; }
    }
    else { // "darkest"
        minA = 1e30;
        for (k = 0; k <= cIdx - exclude; k++)
            if (profSm[k] < minA) { minA = profSm[k]; idxA = k; }
        minB = 1e30;
        for (k = cIdx + exclude; k < nProf; k++)
            if (profSm[k] < minB) { minB = profSm[k]; idxB = k; }
    }

    if (idxA < 0 || idxB < 0) {
        widthArr[i] = NaN;
        ex1Arr[i] = px;  ey1Arr[i] = py;
        ex2Arr[i] = px;  ey2Arr[i] = py;
    } else {
        fA = idxA / (nProf - 1);
        fB = idxB / (nProf - 1);
        lx = ax + (bx - ax) * fA;  ly = ay + (by - ay) * fA;
        rx = ax + (bx - ax) * fB;  ry = ay + (by - ay) * fB;
        wdx = rx - lx;  wdy = ry - ly;
        widthArr[i] = sqrt(wdx*wdx + wdy*wdy) * pw;
        ex1Arr[i] = lx;  ey1Arr[i] = ly;
        ex2Arr[i] = rx;  ey2Arr[i] = ry;
    }
    distArr[i] = d_mm;
}

selectImage(workID);
close();

// --- overlay ---
selectImage(origID);
Overlay.remove;
setColor("yellow");  setLineWidth(3);
Overlay.drawLine(cx1, cy1, cx2, cy2);
setColor("cyan");    setLineWidth(2);
for (i = 0; i < NUM_POINTS; i++)
    Overlay.drawLine(ex1Arr[i], ey1Arr[i], ex2Arr[i], ey2Arr[i]);
Overlay.show;
run("Select None");

if (CONFIRM_BEFORE_LOG) {
    if (!getBoolean(
        "Do the 8 CYAN segments correctly span the root from rim to rim?\n\n"
      + "Yes -> append widths to '" + TABLE_NAME + "' table.\n"
      + "No  -> keep overlay for review but skip logging.")) {
        run("Line Width...", "line=1");
        exit("Results not added. Adjust the centerline and rerun.");
    }
}

if (!isOpen(TABLE_NAME)) Table.create(TABLE_NAME);
selectWindow(TABLE_NAME);
startRow = Table.size;
for (i = 0; i < NUM_POINTS; i++) {
    Table.set("Image",       startRow + i, origTitle);
    Table.set("Method",      startRow + i, DETECTION_METHOD);
    Table.set("Point",       startRow + i, i + 1);
    Table.set("Distance_mm", startRow + i, distArr[i]);
    Table.set("Width_mm",    startRow + i, widthArr[i]);
}
Table.update(TABLE_NAME);

run("Line Width...", "line=1");
showStatus("RootTip: 8 widths logged for " + origTitle);

// ----------------------------------------------------------------
function smoothArray(arr, win) {
    nn = arr.length;
    out = newArray(nn);
    h  = floor(win / 2);
    for (ii = 0; ii < nn; ii++) {
        sum = 0; count = 0;
        for (kk = ii - h; kk <= ii + h; kk++) {
            if (kk >= 0 && kk < nn) { sum += arr[kk]; count++; }
        }
        out[ii] = sum / count;
    }
    return out;
}
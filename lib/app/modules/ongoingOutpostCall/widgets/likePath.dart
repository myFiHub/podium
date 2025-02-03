import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';

//Copy this CustomPainter code to the Bottom of the File

class LikePath extends ConfettiParticle {
  @override
  void paint({
    required ConfettiPhysics physics,
    required Canvas canvas,
  }) {
    canvas.save();
    double referenceX = physics.x;
    double referencY = physics.y;

    Path path_1 = Path();
    path_1.moveTo(63.167 + referenceX, 29.993 + referencY);
    path_1.cubicTo(
        63.167 + referenceX,
        27.165999999999997 + referencY,
        61.226 + referenceX,
        24.305 + referencY,
        57.519000000000005 + referenceX,
        24.305 + referencY);
    path_1.lineTo(40.712 + referenceX, 24.305 + referencY);
    path_1.cubicTo(
        43.113 + referenceX,
        20.009999999999998 + referencY,
        43.819 + referenceX,
        13.969 + referencY,
        42.150000000000006 + referenceX,
        9.549 + referencY);
    path_1.cubicTo(
        40.92400000000001 + referenceX,
        6.298 + referencY,
        38.581 + referenceX,
        4.401 + referencY,
        35.54900000000001 + referenceX,
        4.207999999999999 + referencY);
    path_1.lineTo(35.5 + referenceX, 4.204 + referencY);
    path_1.cubicTo(33.527 + referenceX, 4.083 + referencY, 31.819 + referenceX,
        5.561 + referencY, 31.655 + referenceX, 7.531 + referencY);
    path_1.cubicTo(
        31.223000000000003 + referenceX,
        11.915 + referencY,
        29.302 + referenceX,
        19.669 + referencY,
        26.549 + referenceX,
        22.422 + referencY);
    path_1.cubicTo(
        24.230999999999998 + referenceX,
        24.740000000000002 + referencY,
        22.247 + referenceX,
        25.711000000000002 + referencY,
        18.958 + referenceX,
        27.319000000000003 + referencY);
    path_1.cubicTo(
        18.482 + referenceX,
        27.552000000000003 + referencY,
        17.962 + referenceX,
        27.806 + referencY,
        17.412 + referenceX,
        28.080000000000002 + referencY);
    path_1.cubicTo(
        17.422 + referenceX,
        28.199 + referencY,
        17.427999999999997 + referenceX,
        28.318 + referencY,
        17.427999999999997 + referenceX,
        28.44 + referencY);
    path_1.lineTo(17.427999999999997 + referenceX, 55.914 + referencY);
    path_1.cubicTo(
        17.824999999999996 + referenceX,
        56.050000000000004 + referencY,
        18.217 + referenceX,
        56.185 + referencY,
        18.601999999999997 + referenceX,
        56.317 + referencY);
    path_1.cubicTo(
        24.029999999999998 + referenceX,
        58.188 + referencY,
        28.720999999999997 + referenceX,
        59.803 + referencY,
        35.891 + referenceX,
        59.803 + referencY);
    path_1.lineTo(49.479 + referenceX, 59.803 + referencY);
    path_1.cubicTo(
        53.187 + referenceX,
        59.803 + referencY,
        55.126999999999995 + referenceX,
        56.940999999999995 + referencY,
        55.126999999999995 + referenceX,
        54.114999999999995 + referencY);
    path_1.cubicTo(
        55.126999999999995 + referenceX,
        53.275999999999996 + referencY,
        54.956999999999994 + referenceX,
        52.434999999999995 + referencY,
        54.62 + referenceX,
        51.66499999999999 + referencY);
    path_1.cubicTo(
        55.855 + referenceX,
        51.44299999999999 + referencY,
        56.936 + referenceX,
        50.84899999999999 + referencY,
        57.736999999999995 + referenceX,
        49.93999999999999 + referencY);
    path_1.cubicTo(
        58.645999999999994 + referenceX,
        48.90699999999999 + referencY,
        59.14699999999999 + referenceX,
        47.53399999999999 + referencY,
        59.14699999999999 + referenceX,
        46.07399999999999 + referencY);
    path_1.cubicTo(
        59.14699999999999 + referenceX,
        45.23799999999999 + referencY,
        58.97699999999999 + referenceX,
        44.39699999999999 + referencY,
        58.64099999999999 + referenceX,
        43.62899999999999 + referencY);
    path_1.cubicTo(
        61.61799999999999 + referenceX,
        43.11499999999999 + referencY,
        63.16799999999999 + referenceX,
        40.55999999999999 + referencY,
        63.16799999999999 + referenceX,
        38.03399999999999 + referencY);
    path_1.cubicTo(
        63.16799999999999 + referenceX,
        36.56899999999999 + referencY,
        62.645999999999994 + referenceX,
        35.093999999999994 + referencY,
        61.62799999999999 + referenceX,
        34.013999999999996 + referencY);
    path_1.cubicTo(62.644 + referenceX, 32.933 + referencY, 63.167 + referenceX,
        31.458 + referencY, 63.167 + referenceX, 29.993 + referencY);
    path_1.close();

    Paint paint_1_fill = Paint()..style = PaintingStyle.fill;
    paint_1_fill.color = Colors.green;
    // scale down the path
    canvas.scale(0.5, 0.5);
    canvas.drawPath(path_1, paint_1_fill);
    canvas.restore();
  }
}

class DislikePath extends ConfettiParticle {
  @override
  void paint({
    required ConfettiPhysics physics,
    required Canvas canvas,
  }) {
    canvas.save();
    double referenceX = physics.x;
    double referencY = physics.y;
    Path path_0 = Path();
    path_0.moveTo(88.9310303 + referenceX, 17.0071144 + referencY);
    path_0.lineTo(88.9310303 + referenceX, 49.6464577 + referencY);
    path_0.cubicTo(
        88.9310303 + referenceX,
        53.5491066 + referencY,
        85.7508545 + referenceX,
        56.7256813 + referencY,
        81.8516846 + referenceX,
        56.7256813 + referencY);
    path_0.lineTo(72.909729 + referenceX, 56.7256813 + referencY);
    path_0.cubicTo(
        66.715271 + referenceX,
        68.5397034 + referencY,
        54.3696251 + referenceX,
        67.1269836 + referencY,
        49.526851699999995 + referenceX,
        93.2222595 + referencY);
    path_0.cubicTo(
        49.21606069999999 + referenceX,
        94.8966369 + referencY,
        47.59551629999999 + referenceX,
        95.9747619 + referencY,
        45.953853699999996 + referenceX,
        95.64437860000001 + referencY);
    path_0.cubicTo(
        38.68304069999999 + referenceX,
        94.20297240000001 + referencY,
        33.898494799999995 + referenceX,
        90.88381950000002 + referencY,
        31.736507499999995 + referenceX,
        85.78305050000002 + referencY);
    path_0.cubicTo(
        28.546260899999993 + referenceX,
        78.25857540000001 + referencY,
        32.038326299999994 + referenceX,
        68.81033320000002 + referencY,
        36.2689172 + referenceX,
        61.201999600000015 + referencY);
    path_0.lineTo(24.0808678 + referenceX, 61.201999600000015 + referencY);
    path_0.cubicTo(
        20.0054283 + referenceX,
        61.201999600000015 + referencY,
        15.9165621 + referenceX,
        59.26089850000002 + referencY,
        13.4098482 + referenceX,
        56.136020600000016 + referencY);
    path_0.cubicTo(
        11.395688 + referenceX,
        53.62479010000001 + referencY,
        10.6447725 + referenceX,
        50.625461500000014 + referencY,
        11.299557700000001 + referenceX,
        47.68930430000002 + referencY);
    path_0.lineTo(18.2299767 + referenceX, 16.493076300000016 + referencY);
    path_0.cubicTo(
        19.9029503 + referenceX,
        8.968478200000016 + referencY,
        24.799739900000002 + referenceX,
        4.296114900000017 + referencY,
        31.014034300000002 + referenceX,
        4.296114900000017 + referencY);
    path_0.lineTo(63.1340294 + referenceX, 4.296114900000017 + referencY);
    path_0.cubicTo(
        67.3947754 + referenceX,
        4.296114900000017 + referencY,
        71.3793335 + referenceX,
        6.455416700000017 + referencY,
        73.75610350000001 + referenceX,
        9.927828800000018 + referencY);
    path_0.lineTo(
        81.85168460000001 + referenceX, 9.927828800000018 + referencY);
    path_0.cubicTo(
        85.7508545 + referenceX,
        9.9278288 + referencY,
        88.9310303 + referenceX,
        13.1044645 + referencY,
        88.9310303 + referenceX,
        17.0071144 + referencY);
    path_0.close();

    Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
    paint_0_fill.color = Colors.red;
    // scale down
    canvas.scale(0.3, 0.3);
    canvas.drawPath(path_0, paint_0_fill);
    canvas.restore();
  }
}

class CheerPath extends ConfettiParticle {
  @override
  void paint({
    required ConfettiPhysics physics,
    required Canvas canvas,
  }) {
    canvas.save();
    double referenceX = physics.x;
    double referencY = physics.y;

    Path path_0 = Path();
    path_0.moveTo(84.234 + referenceX, 39.961 + referencY);
    path_0.cubicTo(
        80.90299999999999 + referenceX,
        39.961 + referencY,
        77.77199999999999 + referenceX,
        41.239999999999995 + referencY,
        75.387 + referenceX,
        43.554 + referencY);
    path_0.lineTo(59.816 + referenceX, 56.22 + referencY);
    path_0.cubicTo(
        57.905 + referenceX,
        53.319 + referencY,
        55.623000000000005 + referenceX,
        50.373 + referencY,
        53.054 + referenceX,
        47.528999999999996 + referencY);
    path_0.cubicTo(
        50.29 + referenceX,
        44.467999999999996 + referencY,
        47.429 + referenceX,
        41.773999999999994 + referencY,
        44.619 + referenceX,
        39.525 + referencY);
    path_0.lineTo(56.942 + referenceX, 24.375 + referencY);
    path_0.cubicTo(
        59.256 + referenceX,
        21.990000000000002 + referencY,
        60.536 + referenceX,
        18.859 + referencY,
        60.536 + referenceX,
        15.527 + referencY);
    path_0.cubicTo(
        60.536 + referenceX,
        12.129999999999999 + referencY,
        59.213 + referenceX,
        8.934999999999999 + referencY,
        56.809000000000005 + referenceX,
        6.532 + referencY);
    path_0.cubicTo(
        52.685 + referenceX,
        2.409 + referencY,
        45.976000000000006 + referenceX,
        2.41 + referencY,
        41.852000000000004 + referenceX,
        6.532 + referencY);
    path_0.cubicTo(
        38.397000000000006 + referenceX,
        9.987 + referencY,
        38.397000000000006 + referenceX,
        15.608 + referencY,
        41.852000000000004 + referenceX,
        19.064 + referencY);
    path_0.cubicTo(44.773 + referenceX, 21.982 + referencY, 49.523 + referenceX,
        21.981 + referencY, 52.441 + referenceX, 19.063 + referencY);
    path_0.cubicTo(
        54.933 + referenceX,
        16.570999999999998 + referencY,
        54.933 + referenceX,
        12.517 + referencY,
        52.441 + referenceX,
        10.024999999999999 + referencY);
    path_0.cubicTo(
        51.660000000000004 + referenceX,
        9.243999999999998 + referencY,
        50.393 + referenceX,
        9.243999999999998 + referencY,
        49.613 + referenceX,
        10.024999999999999 + referencY);
    path_0.cubicTo(
        48.832 + referenceX,
        10.806 + referencY,
        48.832 + referenceX,
        12.072 + referencY,
        49.613 + referenceX,
        12.852999999999998 + referencY);
    path_0.cubicTo(
        50.545 + referenceX,
        13.784999999999998 + referencY,
        50.545 + referenceX,
        15.301999999999998 + referencY,
        49.613 + referenceX,
        16.233999999999998 + referencY);
    path_0.cubicTo(
        48.254 + referenceX,
        17.592999999999996 + referencY,
        46.04 + referenceX,
        17.592999999999996 + referencY,
        44.679 + referenceX,
        16.233999999999998 + referencY);
    path_0.cubicTo(
        43.761 + referenceX,
        15.315999999999999 + referencY,
        43.255 + referenceX,
        14.094999999999999 + referencY,
        43.255 + referenceX,
        12.796999999999999 + referencY);
    path_0.cubicTo(
        43.255 + referenceX,
        11.498999999999999 + referencY,
        43.761 + referenceX,
        10.277999999999999 + referencY,
        44.679 + referenceX,
        9.36 + referencY);
    path_0.cubicTo(
        47.242000000000004 + referenceX,
        6.796999999999999 + referencY,
        51.414 + referenceX,
        6.795999999999999 + referencY,
        53.980000000000004 + referenceX,
        9.36 + referencY);
    path_0.cubicTo(
        55.627 + referenceX,
        11.007 + referencY,
        56.535000000000004 + referenceX,
        13.196 + referencY,
        56.535000000000004 + referenceX,
        15.526 + referencY);
    path_0.cubicTo(
        56.535000000000004 + referenceX,
        17.856 + referencY,
        55.628 + referenceX,
        20.045 + referencY,
        53.980000000000004 + referenceX,
        21.691 + referencY);
    path_0.cubicTo(
        53.956 + referenceX,
        21.715 + referencY,
        53.93900000000001 + referenceX,
        21.744 + referencY,
        53.916000000000004 + referenceX,
        21.77 + referencY);
    path_0.cubicTo(53.893 + referenceX, 21.796 + referencY, 53.865 + referenceX,
        21.816 + referencY, 53.843 + referenceX, 21.844 + referencY);
    path_0.lineTo(41.407 + referenceX, 37.134 + referencY);
    path_0.cubicTo(
        36.879 + referenceX,
        34.026 + referencY,
        32.649 + referenceX,
        32.243 + referencY,
        29.395999999999997 + referenceX,
        32.243 + referencY);
    path_0.cubicTo(
        27.728999999999996 + referenceX,
        32.243 + referencY,
        26.345999999999997 + referenceX,
        32.71 + referencY,
        25.254999999999995 + referenceX,
        33.597 + referencY);
    path_0.cubicTo(
        25.182999999999996 + referenceX,
        33.645 + referencY,
        25.111999999999995 + referenceX,
        33.693 + referencY,
        25.046999999999997 + referenceX,
        33.75 + referencY);
    path_0.cubicTo(
        25.038999999999998 + referenceX,
        33.756 + referencY,
        25.029999999999998 + referenceX,
        33.761 + referencY,
        25.022999999999996 + referenceX,
        33.768 + referencY);
    path_0.cubicTo(
        24.250999999999998 + referenceX,
        34.465 + referencY,
        23.536999999999995 + referenceX,
        35.507 + referencY,
        23.201999999999995 + referenceX,
        37.04 + referencY);
    path_0.lineTo(0.667 + referenceX, 81.089 + referencY);
    path_0.cubicTo(
        0.5820000000000001 + referenceX,
        81.255 + referencY,
        0.531 + referenceX,
        81.428 + referencY,
        0.496 + referenceX,
        81.602 + referencY);
    path_0.cubicTo(
        -0.6599999999999999 + referenceX,
        85.527 + referencY,
        0.27 + referenceX,
        89.666 + referencY,
        3.019 + referenceX,
        92.71000000000001 + referencY);
    path_0.cubicTo(
        5.27 + referenceX,
        95.203 + referencY,
        8.374 + referenceX,
        96.56400000000001 + referencY,
        11.632 + referenceX,
        96.56400000000001 + referencY);
    path_0.cubicTo(
        12.363 + referenceX,
        96.56400000000001 + referencY,
        13.103 + referenceX,
        96.489 + referencY,
        13.841999999999999 + referenceX,
        96.349 + referencY);
    path_0.cubicTo(
        14.008999999999999 + referenceX,
        96.32900000000001 + referencY,
        14.175999999999998 + referenceX,
        96.296 + referencY,
        14.339999999999998 + referenceX,
        96.233 + referencY);
    path_0.lineTo(60.528 + referenceX, 78.262 + referencY);
    path_0.cubicTo(61.722 + referenceX, 78.116 + referencY, 62.748 + referenceX,
        77.7 + referencY, 63.595 + referenceX, 77.03 + referencY);
    path_0.cubicTo(63.665 + referenceX, 76.987 + referencY, 63.728 + referenceX,
        76.937 + referencY, 63.791 + referenceX, 76.886 + referencY);
    path_0.cubicTo(
        63.821999999999996 + referenceX,
        76.859 + referencY,
        63.86 + referenceX,
        76.83999999999999 + referencY,
        63.891 + referenceX,
        76.813 + referencY);
    path_0.cubicTo(63.902 + referenceX, 76.803 + referencY, 63.912 + referenceX,
        76.791 + referencY, 63.924 + referenceX, 76.781 + referencY);
    path_0.cubicTo(
        63.938 + referenceX,
        76.76700000000001 + referencY,
        63.951 + referenceX,
        76.754 + referencY,
        63.964999999999996 + referenceX,
        76.74000000000001 + referencY);
    path_0.cubicTo(
        65.75399999999999 + referenceX,
        75.066 + referencY,
        67.191 + referenceX,
        71.53300000000002 + referencY,
        64.128 + referenceX,
        64.15200000000002 + referencY);
    path_0.cubicTo(
        63.527 + referenceX,
        62.70500000000001 + referencY,
        62.776 + referenceX,
        61.20000000000002 + referencY,
        61.916 + referenceX,
        59.667000000000016 + referencY);
    path_0.lineTo(77.916 + referenceX, 46.652000000000015 + referencY);
    path_0.cubicTo(
        77.943 + referenceX,
        46.63000000000002 + referencY,
        77.964 + referenceX,
        46.60200000000002 + referencY,
        77.99 + referenceX,
        46.57800000000002 + referencY);
    path_0.cubicTo(
        78.015 + referenceX,
        46.555000000000014 + referencY,
        78.044 + referenceX,
        46.53800000000002 + referencY,
        78.068 + referenceX,
        46.51400000000002 + referencY);
    path_0.cubicTo(
        79.714 + referenceX,
        44.868000000000016 + referencY,
        81.904 + referenceX,
        43.960000000000015 + referencY,
        84.233 + referenceX,
        43.960000000000015 + referencY);
    path_0.cubicTo(
        86.56200000000001 + referenceX,
        43.960000000000015 + referencY,
        88.75200000000001 + referenceX,
        44.86700000000002 + referencY,
        90.399 + referenceX,
        46.51400000000002 + referencY);
    path_0.cubicTo(
        92.962 + referenceX,
        49.07800000000002 + referencY,
        92.962 + referenceX,
        53.250000000000014 + referencY,
        90.399 + referenceX,
        55.81400000000002 + referencY);
    path_0.cubicTo(
        89.48 + referenceX,
        56.73300000000002 + referencY,
        88.259 + referenceX,
        57.23900000000002 + referencY,
        86.961 + referenceX,
        57.23900000000002 + referencY);
    path_0.cubicTo(
        85.663 + referenceX,
        57.23900000000002 + referencY,
        84.442 + referenceX,
        56.73300000000002 + referencY,
        83.523 + referenceX,
        55.81400000000002 + referencY);
    path_0.cubicTo(
        82.164 + referenceX,
        54.45500000000002 + referencY,
        82.16499999999999 + referenceX,
        52.24100000000002 + referencY,
        83.523 + referenceX,
        50.88100000000002 + referencY);
    path_0.cubicTo(
        84.42699999999999 + referenceX,
        49.97800000000002 + referencY,
        86.00099999999999 + referenceX,
        49.97700000000002 + referencY,
        86.905 + referenceX,
        50.88100000000002 + referencY);
    path_0.cubicTo(
        87.686 + referenceX,
        51.66200000000002 + referencY,
        88.952 + referenceX,
        51.66200000000002 + referencY,
        89.733 + referenceX,
        50.88100000000002 + referencY);
    path_0.cubicTo(
        90.51400000000001 + referenceX,
        50.10000000000002 + referencY,
        90.51400000000001 + referenceX,
        48.83300000000002 + referencY,
        89.733 + referenceX,
        48.05200000000002 + referencY);
    path_0.cubicTo(
        87.241 + referenceX,
        45.560000000000024 + referencY,
        83.186 + referenceX,
        45.55900000000002 + referencY,
        80.694 + referenceX,
        48.05200000000002 + referencY);
    path_0.cubicTo(
        77.777 + referenceX,
        50.97200000000002 + referencY,
        77.777 + referenceX,
        55.72200000000002 + referencY,
        80.69500000000001 + referenceX,
        58.64100000000002 + referencY);
    path_0.cubicTo(
        82.36900000000001 + referenceX,
        60.31500000000002 + referencY,
        84.593 + referenceX,
        61.23800000000002 + referencY,
        86.96100000000001 + referenceX,
        61.23800000000002 + referencY);
    path_0.cubicTo(
        89.32900000000002 + referenceX,
        61.23800000000002 + referencY,
        91.55300000000001 + referenceX,
        60.31500000000002 + referencY,
        93.22700000000002 + referenceX,
        58.64100000000002 + referencY);
    path_0.cubicTo(
        97.35000000000002 + referenceX,
        54.51800000000002 + referencY,
        97.35000000000002 + referenceX,
        47.80800000000002 + referencY,
        93.22700000000002 + referenceX,
        43.68500000000002 + referencY);
    path_0.cubicTo(90.826 + referenceX, 41.284 + referencY, 87.632 + referenceX,
        39.961 + referencY, 84.234 + referenceX, 39.961 + referencY);
    path_0.close();
    path_0.moveTo(24.787 + referenceX, 46.43 + referencY);
    path_0.cubicTo(26.947 + referenceX, 51.633 + referencY, 30.88 + referenceX,
        57.536 + referencY, 35.863 + referenceX, 63.053 + referencY);
    path_0.cubicTo(
        41.722 + referenceX,
        69.54299999999999 + referencY,
        48.019 + referenceX,
        74.419 + referencY,
        53.326 + referenceX,
        76.773 + referencY);
    path_0.lineTo(37.730000000000004 + referenceX, 82.841 + referencY);
    path_0.cubicTo(
        25.650000000000006 + referenceX,
        82.651 + referencY,
        15.857000000000003 + referenceX,
        72.815 + referencY,
        15.615000000000006 + referenceX,
        60.65299999999999 + referencY);
    path_0.lineTo(
        23.991000000000007 + referenceX, 44.27999999999999 + referencY);
    path_0.cubicTo(24.215 + referenceX, 44.961 + referencY, 24.471 + referenceX,
        45.67 + referencY, 24.787 + referenceX, 46.43 + referencY);
    path_0.close();
    path_0.moveTo(5.988 + referenceX, 90.029 + referencY);
    path_0.cubicTo(
        4.173 + referenceX,
        88.01899999999999 + referencY,
        3.5620000000000003 + referenceX,
        85.28399999999999 + referencY,
        4.338000000000001 + referenceX,
        82.695 + referencY);
    path_0.lineTo(12.441 + referenceX, 66.857 + referencY);
    path_0.cubicTo(14.747 + referenceX, 75.845 + referencY, 21.608 + referenceX,
        83.007 + referencY, 30.387 + referenceX, 85.697 + referencY);
    path_0.lineTo(13.115000000000002 + referenceX, 92.418 + referencY);
    path_0.cubicTo(10.462 + referenceX, 92.925 + referencY, 7.803 + referenceX,
        92.04 + referencY, 5.988 + referenceX, 90.029 + referencY);
    path_0.close();
    path_0.moveTo(60.435 + referenceX, 65.686 + referencY);
    path_0.cubicTo(
        62.28 + referenceX,
        70.13000000000001 + referencY,
        62.112 + referenceX,
        72.679 + referencY,
        61.370000000000005 + referenceX,
        73.643 + referencY);
    path_0.lineTo(59.592000000000006 + referenceX, 74.335 + referencY);
    path_0.cubicTo(
        59.56700000000001 + referenceX,
        74.335 + referencY,
        59.54600000000001 + referenceX,
        74.339 + referencY,
        59.52100000000001 + referenceX,
        74.339 + referencY);
    path_0.cubicTo(
        55.50600000000001 + referenceX,
        74.339 + referencY,
        47.111000000000004 + referenceX,
        69.542 + referencY,
        38.83300000000001 + referenceX,
        60.372 + referencY);
    path_0.cubicTo(
        34.14800000000001 + referenceX,
        55.185 + referencY,
        30.473000000000013 + referenceX,
        49.689 + referencY,
        28.48300000000001 + referenceX,
        44.896 + referencY);
    path_0.cubicTo(
        27.196000000000012 + referenceX,
        41.797 + referencY,
        26.89300000000001 + referenceX,
        39.625 + referencY,
        27.074000000000012 + referenceX,
        38.257 + referencY);
    path_0.lineTo(27.932000000000013 + referenceX, 36.579 + referencY);
    path_0.cubicTo(
        28.290000000000013 + referenceX,
        36.36 + referencY,
        28.77700000000001 + referenceX,
        36.243 + referencY,
        29.398000000000014 + referenceX,
        36.243 + referencY);
    path_0.cubicTo(
        31.534000000000013 + referenceX,
        36.243 + referencY,
        34.91800000000001 + referenceX,
        37.615 + referencY,
        38.85800000000002 + referenceX,
        40.269000000000005 + referencY);
    path_0.lineTo(
        34.740000000000016 + referenceX, 45.33200000000001 + referencY);
    path_0.cubicTo(
        34.04300000000001 + referenceX,
        46.18900000000001 + referencY,
        34.173000000000016 + referenceX,
        47.449000000000005 + referencY,
        35.030000000000015 + referenceX,
        48.14600000000001 + referencY);
    path_0.cubicTo(
        35.40100000000002 + referenceX,
        48.44800000000001 + referencY,
        35.847000000000016 + referenceX,
        48.59400000000001 + referencY,
        36.29100000000002 + referenceX,
        48.59400000000001 + referencY);
    path_0.cubicTo(
        36.87200000000002 + referenceX,
        48.59400000000001 + referencY,
        37.44800000000002 + referenceX,
        48.342000000000006 + referencY,
        37.844000000000015 + referenceX,
        47.85600000000001 + referencY);
    path_0.lineTo(
        42.08700000000002 + referenceX, 42.64000000000001 + referencY);
    path_0.cubicTo(
        44.66200000000002 + referenceX,
        44.68800000000001 + referencY,
        47.38000000000002 + referenceX,
        47.21000000000001 + referencY,
        50.088000000000015 + referenceX,
        50.20900000000001 + referencY);
    path_0.cubicTo(
        52.628000000000014 + referenceX,
        53.02200000000001 + referencY,
        54.85800000000002 + referenceX,
        55.92500000000001 + referencY,
        56.69600000000001 + referenceX,
        58.759000000000015 + referencY);
    path_0.lineTo(
        51.90600000000001 + referenceX, 62.655000000000015 + referencY);
    path_0.cubicTo(
        51.049000000000014 + referenceX,
        63.35200000000002 + referencY,
        50.91900000000001 + referenceX,
        64.61200000000001 + referencY,
        51.616000000000014 + referenceX,
        65.46800000000002 + referencY);
    path_0.cubicTo(
        52.012000000000015 + referenceX,
        65.95400000000002 + referencY,
        52.588000000000015 + referenceX,
        66.20600000000002 + referencY,
        53.16900000000001 + referenceX,
        66.20600000000002 + referencY);
    path_0.cubicTo(
        53.61200000000001 + referenceX,
        66.20600000000002 + referencY,
        54.06000000000001 + referenceX,
        66.06000000000002 + referencY,
        54.430000000000014 + referenceX,
        65.75800000000002 + referencY);
    path_0.lineTo(
        58.77000000000001 + referenceX, 62.22800000000002 + referencY);
    path_0.cubicTo(59.406 + referenceX, 63.41 + referencY, 59.971 + referenceX,
        64.568 + referencY, 60.435 + referenceX, 65.686 + referencY);
    path_0.close();

    Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
    paint_0_fill.color = Colors.green;
    canvas.scale(0.5);
    canvas.drawPath(path_0, paint_0_fill);

    Path path_1 = Path();
    path_1.moveTo(64.911 + referenceX, 27.101 + referencY);
    path_1.cubicTo(
        65.19500000000001 + referenceX,
        27.101 + referencY,
        65.484 + referenceX,
        27.04 + referencY,
        65.759 + referenceX,
        26.912 + referencY);
    path_1.cubicTo(68.958 + referenceX, 25.412 + referencY, 74.587 + referenceX,
        21.36 + referencY, 75.389 + referenceX, 15.684 + referencY);
    path_1.cubicTo(
        75.961 + referenceX,
        11.64 + referencY,
        74.077 + referenceX,
        7.685 + referencY,
        69.78999999999999 + referenceX,
        3.930999999999999 + referencY);
    path_1.cubicTo(
        68.96 + referenceX,
        3.201999999999999 + referencY,
        67.695 + referenceX,
        3.285999999999999 + referencY,
        66.96799999999999 + referenceX,
        4.117999999999999 + referencY);
    path_1.cubicTo(
        66.24 + referenceX,
        4.949 + referencY,
        66.32399999999998 + referenceX,
        6.212 + referencY,
        67.15599999999999 + referenceX,
        6.9399999999999995 + referencY);
    path_1.cubicTo(
        70.362 + referenceX,
        9.748 + referencY,
        71.8 + referenceX,
        12.501999999999999 + referencY,
        71.42899999999999 + referenceX,
        15.125 + referencY);
    path_1.cubicTo(
        70.865 + referenceX,
        19.117 + referencY,
        66.36299999999999 + referenceX,
        22.212 + referencY,
        64.06199999999998 + referenceX,
        23.291 + referencY);
    path_1.cubicTo(
        63.06199999999998 + referenceX,
        23.76 + referencY,
        62.630999999999986 + referenceX,
        24.951 + referencY,
        63.09999999999998 + referenceX,
        25.951 + referencY);
    path_1.cubicTo(63.439 + referenceX, 26.675 + referencY, 64.16 + referenceX,
        27.101 + referencY, 64.911 + referenceX, 27.101 + referencY);
    path_1.close();

    Paint paint_1_fill = Paint()..style = PaintingStyle.fill;
    paint_1_fill.color = Colors.green;
    canvas.scale(0.5);
    canvas.drawPath(path_1, paint_1_fill);

    Path path_2 = Path();
    path_2.moveTo(56.537 + referenceX, 39.672 + referencY);
    path_2.cubicTo(
      56.537 + referenceX,
      43.768 + referencY,
      59.869 + referenceX,
      47.101 + referencY,
      63.964999999999996 + referenceX,
      47.101 + referencY,
    );
    path_2.cubicTo(
      68.062 + referenceX,
      47.101 + referencY,
      71.395 + referenceX,
      43.768 + referencY,
      71.395 + referenceX,
      39.672 + referencY,
    );
    path_2.cubicTo(
      71.395 + referenceX,
      35.57599999999999 + referencY,
      68.062 + referenceX,
      32.244 + referencY,
      63.964999999999996 + referenceX,
      32.244 + referencY,
    );
    path_2.cubicTo(
      59.869 + referenceX,
      32.244 + referencY,
      56.537 + referenceX,
      35.576 + referencY,
      56.537 + referenceX,
      39.672 + referencY,
    );
    path_2.close();
    path_2.moveTo(67.395 + referenceX, 39.672 + referencY);
    path_2.cubicTo(
      67.395 + referenceX,
      41.562999999999995 + referencY,
      65.857 + referenceX,
      43.101 + referencY,
      63.964999999999996 + referenceX,
      43.101 + referencY,
    );
    path_2.cubicTo(
      62.074999999999996 + referenceX,
      43.101 + referencY,
      60.537 + referenceX,
      41.563 + referencY,
      60.537 + referenceX,
      39.672 + referencY,
    );
    path_2.cubicTo(
      60.537 + referenceX,
      37.782 + referencY,
      62.074999999999996 + referenceX,
      36.244 + referencY,
      63.964999999999996 + referenceX,
      36.244 + referencY,
    );
    path_2.cubicTo(
      65.856 + referenceX,
      36.244 + referencY,
      67.395 + referenceX,
      37.782 + referencY,
      67.395 + referenceX,
      39.672 + referencY,
    );
    path_2.close();

    Paint paint_2_fill = Paint()..style = PaintingStyle.fill;
    paint_2_fill.color = Colors.green;
    canvas.scale(0.5);
    canvas.drawPath(path_2, paint_2_fill);

    Path path_3 = Path();
    path_3.moveTo(99.902 + referenceX, 17.881 + referencY);
    path_3.cubicTo(
      99.667 + referenceX,
      17.157 + referencY,
      99.041 + referenceX,
      16.63 + referencY,
      98.288 + referenceX,
      16.52 + referencY,
    );
    path_3.lineTo(93.133 + referenceX, 15.77 + referencY);
    path_3.lineTo(90.828 + referenceX, 11.1 + referencY);
    path_3.cubicTo(
      90.491 + referenceX,
      10.417 + referencY,
      89.796 + referenceX,
      9.985 + referencY,
      89.034 + referenceX,
      9.985 + referencY,
    );
    path_3.cubicTo(
      88.272 + referenceX,
      9.985 + referencY,
      87.57700000000001 + referenceX,
      10.417 + referencY,
      87.24000000000001 + referenceX,
      11.1 + referencY,
    );
    path_3.lineTo(84.935 + referenceX, 15.771 + referencY);
    path_3.lineTo(79.781 + referenceX, 16.521 + referencY);
    path_3.cubicTo(
      79.028 + referenceX,
      16.630000000000003 + referencY,
      78.402 + referenceX,
      17.158 + referencY,
      78.167 + referenceX,
      17.882 + referencY,
    );
    path_3.cubicTo(
      77.932 + referenceX,
      18.606 + referencY,
      78.128 + referenceX,
      19.401 + referencY,
      78.673 + referenceX,
      19.932000000000002 + referencY,
    );
    path_3.lineTo(82.402 + referenceX, 23.568 + referencY);
    path_3.lineTo(81.521 + referenceX, 28.702 + referencY);
    path_3.cubicTo(
      81.393 + referenceX,
      29.452 + referencY,
      81.702 + referenceX,
      30.211000000000002 + referencY,
      82.31700000000001 + referenceX,
      30.658 + referencY,
    );
    path_3.cubicTo(
      82.93400000000001 + referenceX,
      31.106 + referencY,
      83.751 + referenceX,
      31.164 + referencY,
      84.423 + referenceX,
      30.810000000000002 + referencY,
    );
    path_3.lineTo(89.033 + referenceX, 28.386000000000003 + referencY);
    path_3.lineTo(93.643 + referenceX, 30.810000000000002 + referencY);
    path_3.cubicTo(
      93.936 + referenceX,
      30.964000000000002 + referencY,
      94.255 + referenceX,
      31.039 + referencY,
      94.574 + referenceX,
      31.039 + referencY,
    );
    path_3.cubicTo(
      94.988 + referenceX,
      31.039 + referencY,
      95.401 + referenceX,
      30.91 + referencY,
      95.75 + referenceX,
      30.657 + referencY,
    );
    path_3.cubicTo(
      96.365 + referenceX,
      30.21 + referencY,
      96.674 + referenceX,
      29.451 + referencY,
      96.546 + referenceX,
      28.701 + referencY,
    );
    path_3.lineTo(95.665 + referenceX, 23.567 + referencY);
    path_3.lineTo(99.39500000000001 + referenceX, 19.931 + referencY);
    path_3.cubicTo(
      99.941 + referenceX,
      19.4 + referencY,
      100.138 + referenceX,
      18.605 + referencY,
      99.902 + referenceX,
      17.881 + referencY,
    );
    path_3.close();
    path_3.moveTo(92.121 + referenceX, 21.437 + referencY);
    path_3.cubicTo(
      91.64999999999999 + referenceX,
      21.896 + referencY,
      91.43499999999999 + referenceX,
      22.558 + referencY,
      91.54599999999999 + referenceX,
      23.207 + referencY,
    );
    path_3.lineTo(91.919 + referenceX, 25.383000000000003 + referencY);
    path_3.lineTo(89.965 + referenceX, 24.356 + referencY);
    path_3.cubicTo(
      89.674 + referenceX,
      24.203000000000003 + referencY,
      89.354 + referenceX,
      24.126 + referencY,
      89.034 + referenceX,
      24.126 + referencY,
    );
    path_3.cubicTo(
      88.71400000000001 + referenceX,
      24.126 + referencY,
      88.394 + referenceX,
      24.203000000000003 + referencY,
      88.10300000000001 + referenceX,
      24.356 + referencY,
    );
    path_3.lineTo(
      86.14900000000002 + referenceX,
      25.383000000000003 + referencY,
    );
    path_3.lineTo(86.52200000000002 + referenceX, 23.207 + referencY);
    path_3.cubicTo(
      86.63200000000002 + referenceX,
      22.559 + referencY,
      86.41800000000002 + referenceX,
      21.896 + referencY,
      85.94700000000002 + referenceX,
      21.437 + referencY,
    );
    path_3.lineTo(84.36600000000001 + referenceX, 19.896 + referencY);
    path_3.lineTo(86.55200000000002 + referenceX, 19.578 + referencY);
    path_3.cubicTo(
      87.20300000000002 + referenceX,
      19.483 + referencY,
      87.76600000000002 + referenceX,
      19.075 + referencY,
      88.05800000000002 + referenceX,
      18.483999999999998 + referencY,
    );
    path_3.lineTo(
        89.03500000000003 + referenceX, 16.503999999999998 + referencY);
    path_3.lineTo(
        90.01200000000003 + referenceX, 18.483999999999998 + referencY);
    path_3.cubicTo(
      90.30400000000003 + referenceX,
      19.073999999999998 + referencY,
      90.86600000000003 + referenceX,
      19.483999999999998 + referencY,
      91.51800000000003 + referenceX,
      19.578 + referencY,
    );
    path_3.lineTo(93.70400000000004 + referenceX, 19.896 + referencY);
    path_3.lineTo(92.121 + referenceX, 21.437 + referencY);
    path_3.close();

    Paint paint_3_fill = Paint()..style = PaintingStyle.fill;
    paint_3_fill.color = Colors.green;
    canvas.scale(0.5);
    canvas.drawPath(path_3, paint_3_fill);

    canvas.restore();
  }
}

class BooPath extends ConfettiParticle {
  @override
  void paint({
    required ConfettiPhysics physics,
    required Canvas canvas,
  }) {
    canvas.save();
    double referenceX = physics.x;
    double referencY = physics.y;
    Path path_0 = Path();
    path_0.moveTo(13 + referenceX, 13 + referencY);
    path_0.cubicTo(10.243 + referenceX, 13 + referencY, 8 + referenceX,
        15.243 + referencY, 8 + referenceX, 18 + referencY);
    path_0.cubicTo(8 + referenceX, 20.757 + referencY, 10.243 + referenceX,
        23 + referencY, 13 + referenceX, 23 + referencY);
    path_0.cubicTo(15.757 + referenceX, 23 + referencY, 18 + referenceX,
        20.757 + referencY, 18 + referenceX, 18 + referencY);
    path_0.cubicTo(18 + referenceX, 15.243 + referencY, 15.757 + referenceX,
        13 + referencY, 13 + referenceX, 13 + referencY);
    path_0.lineTo(13 + referenceX, 13 + referencY);
    path_0.close();
    path_0.moveTo(13 + referenceX, 21 + referencY);
    path_0.cubicTo(11.343 + referenceX, 21 + referencY, 10 + referenceX,
        19.657 + referencY, 10 + referenceX, 18 + referencY);
    path_0.cubicTo(10 + referenceX, 16.343 + referencY, 11.343 + referenceX,
        15 + referencY, 13 + referenceX, 15 + referencY);
    path_0.cubicTo(14.657 + referenceX, 15 + referencY, 16 + referenceX,
        16.343 + referencY, 16 + referenceX, 18 + referencY);
    path_0.cubicTo(16 + referenceX, 19.657 + referencY, 14.657 + referenceX,
        21 + referencY, 13 + referenceX, 21 + referencY);
    path_0.lineTo(13 + referenceX, 21 + referencY);
    path_0.close();

    Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
    paint_0_fill.color = Colors.red;
    canvas.drawPath(path_0, paint_0_fill);

    Path path_1 = Path();
    path_1.moveTo(31 + referenceX, 13 + referencY);
    path_1.cubicTo(28.243 + referenceX, 13 + referencY, 26 + referenceX,
        15.243 + referencY, 26 + referenceX, 18 + referencY);
    path_1.cubicTo(26 + referenceX, 20.757 + referencY, 28.243 + referenceX,
        23 + referencY, 31 + referenceX, 23 + referencY);
    path_1.cubicTo(33.757 + referenceX, 23 + referencY, 36 + referenceX,
        20.757 + referencY, 36 + referenceX, 18 + referencY);
    path_1.cubicTo(36 + referenceX, 15.243 + referencY, 33.757 + referenceX,
        13 + referencY, 31 + referenceX, 13 + referencY);
    path_1.lineTo(31 + referenceX, 13 + referencY);
    path_1.close();
    path_1.moveTo(31 + referenceX, 21 + referencY);
    path_1.cubicTo(29.343 + referenceX, 21 + referencY, 28 + referenceX,
        19.657 + referencY, 28 + referenceX, 18 + referencY);
    path_1.cubicTo(28 + referenceX, 16.343 + referencY, 29.343 + referenceX,
        15 + referencY, 31 + referenceX, 15 + referencY);
    path_1.cubicTo(32.657 + referenceX, 15 + referencY, 34 + referenceX,
        16.343 + referencY, 34 + referenceX, 18 + referencY);
    path_1.cubicTo(34 + referenceX, 19.657 + referencY, 32.657 + referenceX,
        21 + referencY, 31 + referenceX, 21 + referencY);
    path_1.lineTo(31 + referenceX, 21 + referencY);
    path_1.close();

    Paint paint_1_fill = Paint()..style = PaintingStyle.fill;
    paint_1_fill.color = Colors.red;
    canvas.drawPath(path_1, paint_1_fill);

    Path path_2 = Path();
    path_2.moveTo(22 + referenceX, 0 + referencY);
    path_2.cubicTo(9.869 + referenceX, 0 + referencY, 0 + referenceX,
        9.869 + referencY, 0 + referenceX, 22 + referencY);
    path_2.cubicTo(0 + referenceX, 34.131 + referencY, 9.869 + referenceX,
        44 + referencY, 22 + referenceX, 44 + referencY);
    path_2.cubicTo(34.131 + referenceX, 44 + referencY, 44 + referenceX,
        34.131 + referencY, 44 + referenceX, 22 + referencY);
    path_2.cubicTo(44 + referenceX, 9.869 + referencY, 34.131 + referenceX,
        0 + referencY, 22 + referenceX, 0 + referencY);
    path_2.lineTo(22 + referenceX, 0 + referencY);
    path_2.close();
    path_2.moveTo(23.948 + referenceX, 11.258 + referencY);
    path_2.lineTo(30.329 + referenceX, 5.488 + referencY);
    path_2.cubicTo(30.739 + referenceX, 5.119 + referencY, 31.37 + referenceX,
        5.15 + referencY, 31.742 + referenceX, 5.56 + referencY);
    path_2.cubicTo(32.112 + referenceX, 5.97 + referencY, 32.08 + referenceX,
        6.602 + referencY, 31.671 + referenceX, 6.973 + referencY);
    path_2.lineTo(25.29 + referenceX, 12.742 + referencY);
    path_2.cubicTo(25.099 + referenceX, 12.915 + referencY, 24.858 + referenceX,
        13 + referencY, 24.619 + referenceX, 13 + referencY);
    path_2.cubicTo(24.347 + referenceX, 13 + referencY, 24.075 + referenceX,
        12.889 + referencY, 23.877 + referenceX, 12.671 + referencY);
    path_2.cubicTo(23.507 + referenceX, 12.261 + referencY, 23.539 + referenceX,
        11.629 + referencY, 23.948 + referenceX, 11.258 + referencY);
    path_2.lineTo(23.948 + referenceX, 11.258 + referencY);
    path_2.close();
    path_2.moveTo(12.258 + referenceX, 5.56 + referencY);
    path_2.cubicTo(12.631 + referenceX, 5.15 + referencY, 13.262 + referenceX,
        5.119 + referencY, 13.671 + referenceX, 5.488 + referencY);
    path_2.lineTo(20.052 + referenceX, 11.258 + referencY);
    path_2.cubicTo(20.461 + referenceX, 11.629 + referencY, 20.493 + referenceX,
        12.261 + referencY, 20.123 + referenceX, 12.671 + referencY);
    path_2.cubicTo(19.925 + referenceX, 12.889 + referencY, 19.653 + referenceX,
        13 + referencY, 19.381 + referenceX, 13 + referencY);
    path_2.cubicTo(19.142 + referenceX, 13 + referencY, 18.901 + referenceX,
        12.915 + referencY, 18.71 + referenceX, 12.742 + referencY);
    path_2.lineTo(12.329 + referenceX, 6.973 + referencY);
    path_2.cubicTo(11.92 + referenceX, 6.602 + referencY, 11.888 + referenceX,
        5.97 + referencY, 12.258 + referenceX, 5.56 + referencY);
    path_2.lineTo(12.258 + referenceX, 5.56 + referencY);
    path_2.close();
    path_2.moveTo(6 + referenceX, 18 + referencY);
    path_2.cubicTo(6 + referenceX, 14.141 + referencY, 9.141 + referenceX,
        11 + referencY, 13 + referenceX, 11 + referencY);
    path_2.cubicTo(16.859 + referenceX, 11 + referencY, 20 + referenceX,
        14.141 + referencY, 20 + referenceX, 18 + referencY);
    path_2.cubicTo(20 + referenceX, 21.859 + referencY, 16.859 + referenceX,
        25 + referencY, 13 + referenceX, 25 + referencY);
    path_2.cubicTo(9.141 + referenceX, 25 + referencY, 6 + referenceX,
        21.859 + referencY, 6 + referenceX, 18 + referencY);
    path_2.lineTo(6 + referenceX, 18 + referencY);
    path_2.close();
    path_2.moveTo(22 + referenceX, 38 + referencY);
    path_2.cubicTo(18.691 + referenceX, 38 + referencY, 16 + referenceX,
        35.309 + referencY, 16 + referenceX, 32 + referencY);
    path_2.cubicTo(16 + referenceX, 28.691 + referencY, 18.691 + referenceX,
        26 + referencY, 22 + referenceX, 26 + referencY);
    path_2.cubicTo(25.309 + referenceX, 26 + referencY, 28 + referenceX,
        28.691 + referencY, 28 + referenceX, 32 + referencY);
    path_2.cubicTo(28 + referenceX, 35.309 + referencY, 25.309 + referenceX,
        38 + referencY, 22 + referenceX, 38 + referencY);
    path_2.lineTo(22 + referenceX, 38 + referencY);
    path_2.close();
    path_2.moveTo(31 + referenceX, 25 + referencY);
    path_2.cubicTo(27.141 + referenceX, 25 + referencY, 24 + referenceX,
        21.859 + referencY, 24 + referenceX, 18 + referencY);
    path_2.cubicTo(24 + referenceX, 14.141 + referencY, 27.141 + referenceX,
        11 + referencY, 31 + referenceX, 11 + referencY);
    path_2.cubicTo(34.859 + referenceX, 11 + referencY, 38 + referenceX,
        14.141 + referencY, 38 + referenceX, 18 + referencY);
    path_2.cubicTo(38 + referenceX, 21.859 + referencY, 34.859 + referenceX,
        25 + referencY, 31 + referenceX, 25 + referencY);
    path_2.lineTo(31 + referenceX, 25 + referencY);
    path_2.close();

    Paint paint_2_fill = Paint()..style = PaintingStyle.fill;
    paint_2_fill.color = Colors.red;
    canvas.drawPath(path_2, paint_2_fill);
    canvas.restore();
  }
}

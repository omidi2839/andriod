import 'package:flutter/material.dart';

// A quiet eight-point textile motif, drawn locally; no remote decorative imagery.
class TextilePattern extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final paint=Paint()..color=const Color(0xffe3c791).withOpacity(.13)..style=PaintingStyle.stroke..strokeWidth=.8;
    for(double y=0;y<size.height+38;y+=38){
      for(double x=0;x<size.width+38;x+=38){
        final path=Path()..moveTo(x,y-15)..lineTo(x+5,y-5)..lineTo(x+15,y)..lineTo(x+5,y+5)..lineTo(x,y+15)..lineTo(x-5,y+5)..lineTo(x-15,y)..lineTo(x-5,y-5)..close();
        canvas.drawPath(path,paint);canvas.drawCircle(Offset(x+19,y+19),2,paint);
      }
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

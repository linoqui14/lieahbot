

import 'package:flutter/material.dart';

import '../tools/my_colors.dart';



class CustomTextField extends StatefulWidget{
  CustomTextField({
    Key? key,
    required this.hint,
    required this.padding,
    this.obscureText = false,
    this.rTopRight = 10,
    this.rTopLeft = 10,
    this.rBottomRight = 10,
    this.rBottomLeft = 10,
    this.color = MyColors.red,
    required this.controller,
    this.filled = false,
    this.icon,
    this.enable = true,
    this.readonly = false,
    this.suffix
  }) : super(key: key);

  final String hint;
  final EdgeInsets padding;
  IconData? icon;
  Widget? suffix;
  bool obscureText = false;
  double rTopRight;
  double rTopLeft ;
  double rBottomRight;
  double rBottomLeft;
  Color color;
  bool filled;
  bool enable;
  bool readonly;
  TextEditingController controller;
  @override
  State<CustomTextField> createState() => _CustomTextFieldState();



}

class _CustomTextFieldState extends State<CustomTextField>{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: widget.padding,
      child: TextField(
        minLines: 1,
        maxLines: 3,
        readOnly: widget.readonly,
        enabled:widget.enable,
        controller: widget.controller,
        obscureText: widget.obscureText,
        style: TextStyle(
          color: widget.color,
        ),
        decoration: InputDecoration(

            suffixIcon:widget.suffix,
            prefixIcon: widget.icon != null?Icon(widget.icon,color: widget.color,size: 20,):null,
            filled: widget.filled,
            contentPadding: EdgeInsets.only(bottom: 0,top: 10,left: 10,right: 10),
            labelText: widget.hint,
            labelStyle: TextStyle(
              color: widget.color,
            ),
            border: OutlineInputBorder(
                borderSide: BorderSide(
                    color:  widget.color
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(widget.rBottomRight),
                  bottomLeft: Radius.circular(widget.rBottomLeft),
                  topRight: Radius.circular(widget.rTopRight),
                  topLeft: Radius.circular(widget.rTopLeft),
                )
            ),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color:  widget.color
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(widget.rBottomRight),
                  bottomLeft: Radius.circular(widget.rBottomLeft),
                  topRight: Radius.circular(widget.rTopRight),
                  topLeft: Radius.circular(widget.rTopLeft),
                )
            ),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: widget.color.withAlpha(100)
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(widget.rBottomRight),
                  bottomLeft: Radius.circular(widget.rBottomLeft),
                  topRight: Radius.circular(widget.rTopRight),
                  topLeft: Radius.circular(widget.rTopLeft),
                )
            ),
            disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: widget.color.withAlpha(100)
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(widget.rBottomRight),
                  bottomLeft: Radius.circular(widget.rBottomLeft),
                  topRight: Radius.circular(widget.rTopRight),
                  topLeft: Radius.circular(widget.rTopLeft),
                )
            ),
            hintText: widget.hint,
            hintStyle: TextStyle(
                color:  widget.color.withAlpha(100)
            )
        ),
      ),
    );
  }


}

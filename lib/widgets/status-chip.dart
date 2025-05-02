import 'package:flutter/material.dart';

Widget buildStatusChip(String status) {
    Color chipColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'new':
        chipColor = Colors.blue;
        statusText = 'Baru';
        break;
      case 'processing':
        chipColor = Colors.orange;
        statusText = 'Diproses';
        break;
      case 'closed':
        chipColor = Colors.green;
        statusText = 'Selesai';
        break;
      default:
        chipColor = Colors.grey;
        statusText = status;
    }

    return Chip(
      label: Text(
        statusText,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }
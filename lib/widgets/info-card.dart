import 'package:flutter/material.dart';

Widget infoCard(
  BuildContext context,
  String title,
  String description,
  String imagePath,
  String route,
) {
  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(
        context,
        '/info-detail',
        arguments: {
          'title': title,
          'description': description,
          'image': imagePath,
        },
      );
    },
    child: Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ClipRRect(
          //   borderRadius: const BorderRadius.only(
          //     topLeft: Radius.circular(12),
          //     topRight: Radius.circular(12),
          //   ),
          //   child: Image.asset(
          //     imagePath,
          //     height: 70,
          //     width: double.infinity,
          //     fit: BoxFit.cover,
          //     errorBuilder: (context, error, stackTrace) {
          //       return Container(
          //         height: 100,
          //         color: Colors.grey[300],
          //         child: const Icon(Icons.image_not_supported),
          //       );
          //     },
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

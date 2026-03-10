// import 'package:batti_nala/features/citizen_dashboard/models/issue_model.dart';
// import 'package:flutter/material.dart';

// class IssueDetailScreen extends StatefulWidget {
//   final Issue issue;
//   final Map user;
//   final VoidCallback onBack;
//   final VoidCallback onUpdate;

//   const IssueDetailScreen({
//     super.key,
//     required this.issue,
//     required this.user,
//     required this.onBack,
//     required this.onUpdate,
//   });

//   @override
//   State<IssueDetailScreen> createState() => _IssueDetailScreenState();
// }

// class _IssueDetailScreenState extends State<IssueDetailScreen> {
//   bool isUpdating = false;

//   void handleStatusUpdate() async {
//     setState(() => isUpdating = true);

//     await Future.delayed(const Duration(seconds: 1));

//     widget.onUpdate();
//   }

//   String getNextStatusLabel() {
//     if (widget.issue.status == IssueStatus.pending) return "Start Working";
//     if (widget.issue.status == IssueStatus.inProgress) {
//       return "Mark as Resolved";
//     }
//     return "Completed";
//   }

//   @override
//   Widget build(BuildContext context) {
//     final issue = widget.issue;

//     return Scaffold(
//       backgroundColor: const Color(0xfff3f4f6),

//       body: SafeArea(
//         child: Column(
//           children: [
//             /// HEADER
//             Container(
//               color: const Color(0xff1e3a8a),
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: widget.onBack,
//                     child: const Row(
//                       children: [
//                         Icon(Icons.arrow_back, color: Colors.white),
//                         SizedBox(width: 6),
//                         Text("Back", style: TextStyle(color: Colors.white)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             /// CONTENT
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     /// ISSUE HEADER
//                     _card(
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Row(
//                             children: [
//                               Container(
//                                 width: 48,
//                                 height: 48,
//                                 decoration: BoxDecoration(
//                                   color: issue.category == "water"
//                                       ? Colors.blue.shade100
//                                       : Colors.yellow.shade100,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Icon(
//                                   issue.category == "water"
//                                       ? Icons.water_drop
//                                       : Icons.bolt,
//                                   color: issue.category == "water"
//                                       ? Colors.blue
//                                       : Colors.orange,
//                                 ),
//                               ),

//                               const SizedBox(width: 12),

//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     issue.category == "water"
//                                         ? "Water Issue"
//                                         : "Electricity Issue",
//                                     style: const TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.grey,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     "Issue #${issue.id}",
//                                     style: const TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),

//                           // _statusBadge(issue.status),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     /// DESCRIPTION
//                     _card(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             "Description",
//                             style: TextStyle(fontSize: 12, color: Colors.grey),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(issue.description),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     /// LOCATION
//                     _card(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Row(
//                             children: [
//                               Icon(Icons.location_on, size: 16),
//                               SizedBox(width: 6),
//                               Text(
//                                 "Location",
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 8),

//                           Text(issue.locationName),

//                           const SizedBox(height: 4),

//                           // Text(
//                           //   "${issue.location.lat}, ${issue.location.lng}",
//                           //   style: const TextStyle(
//                           //     fontSize: 12,
//                           //     color: Colors.grey,
//                           //   ),
//                           // ),
//                           const SizedBox(height: 8),

//                           const Text(
//                             "View on Map",
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.blue,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     /// REPORT INFO
//                     _card(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             "Report Information",
//                             style: TextStyle(fontSize: 12, color: Colors.grey),
//                           ),

//                           const SizedBox(height: 12),

//                           Row(
//                             children: [
//                               const Icon(
//                                 Icons.person,
//                                 size: 18,
//                                 color: Colors.grey,
//                               ),
//                               const SizedBox(width: 10),
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text(
//                                     "Reported by",
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.grey,
//                                     ),
//                                   ),
//                                   Text(issue.reportedAt),
//                                 ],
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 12),

//                           Row(
//                             children: [
//                               const Icon(
//                                 Icons.calendar_today,
//                                 size: 18,
//                                 color: Colors.grey,
//                               ),
//                               const SizedBox(width: 10),
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text(
//                                     "Reported at",
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.grey,
//                                     ),
//                                   ),
//                                   Text(issue.reportedAt),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     /// STAFF ACTION
//                     if (widget.user["role"] == "staff" &&
//                         issue.status != issue.resolved)
//                       _card(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               "Actions",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             ),

//                             const SizedBox(height: 10),

//                             SizedBox(
//                               width: double.infinity,
//                               child: ElevatedButton(
//                                 onPressed: isUpdating
//                                     ? null
//                                     : handleStatusUpdate,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.red.shade700,
//                                   padding: const EdgeInsets.symmetric(
//                                     vertical: 14,
//                                   ),
//                                 ),
//                                 child: isUpdating
//                                     ? const SizedBox(
//                                         height: 18,
//                                         width: 18,
//                                         child: CircularProgressIndicator(
//                                           color: Colors.white,
//                                           strokeWidth: 2,
//                                         ),
//                                       )
//                                     : Text(getNextStatusLabel()),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                     const SizedBox(height: 16),

//                     /// RESOLVED MESSAGE
//                     if (issue.status == IssueStatus.resolved)
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.green.shade50,
//                           border: Border.all(color: Colors.green.shade200),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Column(
//                           children: const [
//                             CircleAvatar(
//                               radius: 22,
//                               backgroundColor: Colors.green,
//                               child: Icon(Icons.check, color: Colors.white),
//                             ),
//                             SizedBox(height: 10),
//                             Text(
//                               "This issue has been resolved!",
//                               style: TextStyle(color: Colors.green),
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _card({required Widget child}) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: const Color(0xffe5e7eb)),
//       ),
//       child: child,
//     );
//   }

//   Widget _statusBadge(String status) {
//     Color color = Colors.orange;

//     if (status == "resolved") color = Colors.green;
//     if (status == "in-progress") color = Colors.blue;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(.15),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(status, style: TextStyle(color: color, fontSize: 12)),
//     );
//   }
// }

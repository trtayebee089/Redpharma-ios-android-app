import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UploadPrescriptionButton extends StatelessWidget {
  final String phoneNumber;
  final String message;

  const UploadPrescriptionButton({
    Key? key,
    required this.phoneNumber,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.green.withOpacity(0.15),
        highlightColor: Colors.transparent,
        onTap: () async {
          final formattedPhone = phoneNumber
              .replaceAll('+', '')
              .replaceAll(' ', '');
          final encodedText = Uri.encodeComponent(message);

          final nativeUri = Uri.parse(
            'whatsapp://send?phone=$formattedPhone&text=$encodedText',
          );

          final webUri = Uri.parse(
            'https://wa.me/$formattedPhone?text=$encodedText',
          );

          try {
            if (await canLaunchUrl(nativeUri)) {
              final ok = await launchUrl(
                nativeUri,
                mode: LaunchMode.externalNonBrowserApplication,
              );
              if (!ok) {
                await launchUrl(webUri, mode: LaunchMode.externalApplication);
              }
              return;
            }

            if (await canLaunchUrl(webUri)) {
              await launchUrl(webUri, mode: LaunchMode.externalApplication);
              return;
            }

            // If both fail, notify user
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to open WhatsApp.')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to open WhatsApp: $e')),
            );
          }
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 168, 255, 175), // lighter top
                Color.fromARGB(255, 147, 255, 156), // fresh mint green
                Color.fromARGB(255, 168, 255, 175), // deep green accent
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                height: 65,
                width: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Color(0xFF25D366),
                    size: 34,
                  ),
                ),
              ),

              const SizedBox(width: 18),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Upload Your Prescription',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 87, 32),
                        height: 1.2,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Send your prescription directly on WhatsApp for a quick response.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 0, 119, 44),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Color.fromARGB(255, 0, 187, 25)),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.arrowRight,
                    color: Color.fromARGB(255, 0, 187, 25),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

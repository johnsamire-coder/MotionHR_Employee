$ErrorActionPreference = 'Stop'
$project = 'C:\MotionHR\motionhr_employee'
Set-Location $project

Write-Host '=== Batch 2: Widgets ===' -ForegroundColor Cyan

function Write-Utf8File {
    param([string]$RelativePath, [string]$Content)
    $fullPath = Join-Path $project $RelativePath
    New-Item -ItemType Directory -Force -Path (Split-Path $fullPath -Parent) | Out-Null
    Set-Content -Path $fullPath -Value $Content -Encoding UTF8
    Write-Host "Created: $RelativePath" -ForegroundColor Green
}

Write-Utf8File 'lib\widgets\notification_bell_button.dart' @'
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationBellButton extends StatelessWidget {
  final Color color;
  final Widget Function(BuildContext) notificationsScreenBuilder;

  const NotificationBellButton({
    super.key,
    this.color = Colors.white,
    required this.notificationsScreenBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.unreadCount,
      builder: (context, count, _) {
        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications, color: color),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: notificationsScreenBuilder,
                  ),
                );
                NotificationService.fetchUnreadCount();
              },
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
'@

Write-Utf8File 'lib\widgets\app_loading.dart' @'
import 'package:flutter/material.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
'@

Write-Utf8File 'lib\widgets\app_empty.dart' @'
import 'package:flutter/material.dart';

class AppEmpty extends StatelessWidget {
  final String message;
  final IconData? icon;

  const AppEmpty({
    super.key,
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.inbox,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
'@

Write-Utf8File 'lib\widgets\app_snackbar.dart' @'
import 'package:flutter/material.dart';

class AppSnackbar {
  static void success(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  static void error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  static void warning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  static void info(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
'@

Write-Host ''
Write-Host '=== Batch 2 Done ===' -ForegroundColor Cyan
Write-Host 'Created: lib/widgets/' -ForegroundColor Green
Write-Host 'main.dart was NOT modified.' -ForegroundColor Yellow
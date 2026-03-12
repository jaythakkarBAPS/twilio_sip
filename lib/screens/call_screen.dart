import 'package:flutter/material.dart';
import 'package:twilio_voice/twilio_voice.dart';
import '../services/twilio_service.dart';

class CallScreen extends StatefulWidget {
  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final TextEditingController _numberController = TextEditingController();
  final TwilioService _twilioService = TwilioService();
  bool _isMuted = false;
  bool _isSpeaker = false;
  CallEvent? _currentCallEvent;

  @override
  void initState() {
    super.initState();
    _twilioService.callEvents.listen((event) {
      setState(() {
        _currentCallEvent = event;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isCallActive = _currentCallEvent != null && 
        (_currentCallEvent == CallEvent.connected || _currentCallEvent == CallEvent.ringing);

    return Scaffold(
      appBar: AppBar(
        title: Text('Twilio Call Center'),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isCallActive) ...[
              TextField(
                controller: _numberController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '+1 234 567 890',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              SizedBox(height: 32),
              FloatingActionButton.large(
                onPressed: () => _twilioService.makeCall(_numberController.text),
                backgroundColor: Colors.green,
                child: Icon(Icons.call, size: 40, color: Colors.white),
              ),
            ] else ...[
              Text(
                'Status: ${_currentCallEvent.toString().split('.').last}',
                style: TextStyle(fontSize: 18, color: Colors.blueGrey),
              ),
              SizedBox(height: 24),
              Text(
                _numberController.text.isEmpty ? 'Incoming Call' : _numberController.text,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _IconButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.red : Colors.grey,
                    onPressed: () {
                      setState(() => _isMuted = !_isMuted);
                      _twilioService.toggleMute(_isMuted);
                    },
                  ),
                  _IconButton(
                    icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                    color: _isSpeaker ? Colors.blue : Colors.grey,
                    onPressed: () {
                      setState(() => _isSpeaker = !_isSpeaker);
                      _twilioService.toggleSpeaker(_isSpeaker);
                    },
                  ),
                ],
              ),
              SizedBox(height: 48),
              FloatingActionButton.large(
                onPressed: () => _twilioService.hangUp(),
                backgroundColor: Colors.red,
                child: Icon(Icons.call_end, size: 40, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _IconButton({required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
        child: Icon(icon, size: 32, color: color),
      ),
    );
  }
}

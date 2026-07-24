import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/edge_theme.dart';
import '../domain/llm_isolate.dart';
import '../domain/model_downloader.dart';

class OracleScreen extends ConsumerStatefulWidget {
  const OracleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OracleScreen> createState() => _OracleScreenState();
}

class _OracleScreenState extends ConsumerState<OracleScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // ValueNotifier for UI rendering efficiency (PRD ORC-F4)
  final ValueNotifier<String> _responseNotifier = ValueNotifier<String>('');
  
  StreamSubscription? _tokenSubscription;
  bool _isGenerating = false;
  double _downloadProgress = 0.0;
  bool _isModelDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
    
    // Initialize Isolate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(llmIsolateProvider).init();
      
      _tokenSubscription = ref.read(llmIsolateProvider).tokenStream.listen((token) {
        _responseNotifier.value += token;
        _scrollToBottom();
      });
    });
  }

  Future<void> _checkModelStatus() async {
    final isDownloaded = await ref.read(modelDownloaderProvider).isModelDownloaded();
    if (mounted) setState(() => _isModelDownloaded = isDownloaded);
  }

  void _startDownload() {
    setState(() => _downloadProgress = 0.01);
    ref.read(modelDownloaderProvider).downloadModel().listen((progress) {
      if (mounted) setState(() => _downloadProgress = progress);
    }, onDone: () {
      if (mounted) setState(() => _isModelDownloaded = true);
    }, onError: (e) {
      if (mounted) setState(() => _downloadProgress = 0.0);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    });
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _responseNotifier.dispose();
    // For a real app, you might not want to dispose the isolate every time you leave the screen
    // but for benchmarking it ensures clean memory.
    ref.read(llmIsolateProvider).dispose();
    super.dispose();
  }

  void _submitPrompt() {
    final text = _textController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _responseNotifier.value = 'User: $text\n\nOracle: ';
    });
    
    _textController.clear();
    ref.read(llmIsolateProvider).prompt(text);
    
    // Simulate generation finish since our mock isolate doesn't have robust callback yet
    // In a real implementation we listen for [DONE] event in the stream
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ORACLE (LLM)', style: EdgeTheme.monoTextStyle),
        backgroundColor: EdgeTheme.surfaceRaised,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: ValueListenableBuilder<String>(
                  valueListenable: _responseNotifier,
                  builder: (context, value, child) {
                    if (value.isEmpty) {
                      if (!_isModelDownloaded) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SYSTEM ONLINE.\nAwaiting model weights...',
                                textAlign: TextAlign.center,
                                style: EdgeTheme.monoTextStyle.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Consumer(
                                builder: (context, ref, _) {
                                  return ElevatedButton.icon(
                                    onPressed: _downloadProgress > 0 ? null : _startDownload,
                                    icon: const Icon(Icons.download),
                                    label: Text('DOWNLOAD QWEN 2.5 0.5B (350MB)', style: EdgeTheme.monoTextStyle),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: EdgeTheme.accentAction,
                                      foregroundColor: Colors.white,
                                    ),
                                  );
                                }
                              ),
                              if (_downloadProgress > 0 && _downloadProgress < 1.0) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: 200,
                                  child: LinearProgressIndicator(
                                    value: _downloadProgress,
                                    backgroundColor: EdgeTheme.surfaceRaised,
                                    color: EdgeTheme.stateGood,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                                  style: EdgeTheme.monoTextStyle,
                                )
                              ]
                            ],
                          ),
                        );
                      }
                      
                      return Center(
                        child: Text(
                          'MODEL LOADED.\nAwaiting instructions...',
                          textAlign: TextAlign.center,
                          style: EdgeTheme.monoTextStyle.copyWith(
                            color: EdgeTheme.stateGood,
                          ),
                        ),
                      );
                    }
                    return Text(
                      value,
                      style: EdgeTheme.monoTextStyle.copyWith(fontSize: 14),
                    );
                  },
                ),
              ),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: EdgeTheme.surfaceOverlay,
        border: Border(top: BorderSide(color: EdgeTheme.surfaceRaised)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: EdgeTheme.monoTextStyle,
                decoration: InputDecoration(
                  hintText: 'Enter prompt...',
                  hintStyle: TextStyle(color: Colors.white30),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: EdgeTheme.surfaceRaised),
                  ),
                  filled: true,
                  fillColor: EdgeTheme.surfaceRaised,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) => _submitPrompt(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.send, color: _isGenerating ? Colors.white30 : EdgeTheme.accentAction),
              onPressed: _isGenerating ? null : _submitPrompt,
            ),
          ],
        ),
      ),
    );
  }
}

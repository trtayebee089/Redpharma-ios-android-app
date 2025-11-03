import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:redpharmabd_app/widgets/products_grid_item.dart';
import 'package:redpharmabd_app/main.dart';
import 'package:redpharmabd_app/widgets/custom_snackbar.dart';
import 'package:redpharmabd_app/constants/default_theme.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  const SearchResultsScreen({Key? key, required this.initialQuery})
    : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final String _base = 'https://redpharma-api.techrajshahi.com';
  List<dynamic> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String _lastQuery = '';

  Timer? _debouncer;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialQuery;
    _lastQuery = widget.initialQuery;
    _fetchResults(reset: true);

    _scrollCtrl.addListener(() {
      if (_hasMore &&
          !_isLoadingMore &&
          _scrollCtrl.position.pixels >=
              _scrollCtrl.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debouncer?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debouncer?.cancel();
    _debouncer = Timer(const Duration(milliseconds: 400), () {
      final q = v.trim();
      if (q != _lastQuery) {
        _lastQuery = q;
        _fetchResults(reset: true);
      }
    });
  }

  Future<void> _fetchResults({bool reset = false}) async {
    final q = _lastQuery.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _hasMore = false;
      });
      return;
    }

    if (reset) {
      setState(() {
        _isLoading = true;
        _results = [];
        _page = 1;
        _hasMore = true;
      });
    }

    try {
      final encoded = Uri.encodeComponent(q);
      final uri = Uri.parse('$_base/api/search/$encoded?page=$_page');

      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);

        // The API might return either a List or { data: [...] }
        final List<dynamic> items = body is List
            ? body
            : (body is Map && body['data'] is List)
            ? List<dynamic>.from(body['data'])
            : <dynamic>[];

        setState(() {
          _results.addAll(items);
          // If fewer results than a typical page size (guess 20), stop loading more
          _hasMore = items.length >= 20;
        });
      } else {
        _showSnack('Search failed: ${resp.statusCode}');
        setState(() => _hasMore = false);
      }
    } on TimeoutException {
      _showSnack('Request timed out. Please try again.');
    } catch (e) {
      _showSnack('Error: $e');
      setState(() => _hasMore = false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _page += 1;
    await _fetchResults(reset: false);
  }

  void _submit() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    _lastQuery = q;
    _fetchResults(reset: true);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    AppSnackbar.show(
      context,
      message: msg,
      icon: Icons.check_circle_outline,
      backgroundColor: DefaultTheme.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: _searchField(),
        automaticallyImplyLeading: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? _emptyState()
          : RefreshIndicator(
              onRefresh: () => _fetchResults(reset: true),
              child: CustomScrollView(
                controller: _scrollCtrl,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 6,
                            childAspectRatio: 0.90,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = _results[index];
                        return ProductGridItem(product: item);
                      }, childCount: _results.length),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _isLoadingMore
                            ? const CircularProgressIndicator()
                            : _hasMore
                            ? const SizedBox.shrink()
                            : const Text(
                                'No more results',
                                style: TextStyle(color: Colors.grey),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Top search field in the AppBar
  Widget _searchField() {
    return TextField(
      controller: _searchCtrl,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _submit(),
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: 'Search medicines, brands, categories...',
        isDense: true,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchCtrl.clear();
                    _lastQuery = '';
                    _results.clear();
                    _hasMore = false;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFFDFDFD),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent.shade200, width: 1.2),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_outlined,
              size: 80,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              _lastQuery.isEmpty
                  ? 'Type to search'
                  : 'No results for “$_lastQuery”',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try another keyword or return to the home page.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // go back to home
                    mainScreenKey.currentState
                        ?.switchToHomeTab(); // switch to home tab
                    homeScreenKey.currentState
                        ?.clearSearch(); // clear home search bar
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Return To Home'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 217, 217),
                    foregroundColor: const Color.fromARGB(255, 164, 34, 34),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(
                      color: Color.fromARGB(255, 242, 214, 214),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

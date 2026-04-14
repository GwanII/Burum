import 'package:burum/models/errand_manage_item.dart';
import 'package:burum/services/errand_management_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:burum/src/createErrandScreen.dart';

class ErrandManagementScreen extends StatefulWidget {
  const ErrandManagementScreen({super.key});

  @override
  State<ErrandManagementScreen> createState() => _ErrandManagementScreenState();
}

class _ErrandManagementScreenState extends State<ErrandManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ErrandManagementService _service = ErrandManagementService();

  bool _isLoading = true;
  List<ErrandManageItem> _requestedErrands = [];
  List<ErrandManageItem> _assignedErrands = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _service.getMyRequestedErrands(),
        _service.getMyAssignedErrands(),
      ]);

      setState(() {
        _requestedErrands = results[0] as List<ErrandManageItem>;
        _assignedErrands = results[1] as List<ErrandManageItem>;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('심부름 목록 조회 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCost(int cost) {
    return NumberFormat('#,###').format(cost);
  }

  String _formatDeadline(DateTime? deadline) {
    if (deadline == null) return '일정 협의';
    return '${deadline.month}월 ${deadline.day}일';
  }

  String? _resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }

    // 서버 정적 경로가 /uploads 이므로 상대경로 보정
    if (rawUrl.startsWith('/uploads')) {
      return 'http://localhost:3000$rawUrl';
    }
    if (rawUrl.startsWith('uploads/')) {
      return 'http://localhost:3000/$rawUrl';
    }

    return rawUrl;
  }

  Future<void> _onCompletePressed(ErrandManageItem item) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReviewDialog(itemTitle: item.title),
    );

    if (result == true) {
      try {
        await _service.completeErrand(item.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('심부름 완료 처리되었습니다.')),
        );
        await _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('완료 처리 실패: $e')),
        );
      }
    }
  }

  Future<void> _onAddCalendarPressed(ErrandManageItem item) async {
    try {
      await _service.addToCalendar(item);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정에 추가되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일정 추가 실패: $e')),
      );
    }
  }

  Widget _buildImage(String? imageUrl) {
    final resolved = _resolveImageUrl(imageUrl);

    if (resolved == null) {
      return Container(
        width: 86,
        height: 86,
        color: const Color(0xFFEAEAEA),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.network(
        resolved,
        width: 86,
        height: 86,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 86,
            height: 86,
            color: const Color(0xFFEAEAEA),
          );
        },
      ),
    );
  }

  Widget _buildRequestedCard(ErrandManageItem item) {
    final isCompleted = item.status == 'COMPLETED';
    final canComplete = item.status == 'IN_PROGRESS' && item.assignedUserId != null;
    final showApplicantNotice =
        item.status == 'WAITING' && item.applicantCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFD4D4D4)),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(item.imageUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatCost(item.cost)}원/${_formatDeadline(item.deadline)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.blueGrey),
                          const SizedBox(width: 2),
                          Text(
                            '${item.applicantCount}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.handshake, size: 16, color: Colors.blueGrey),
                          const SizedBox(width: 2),
                          Text(
                            item.assignedUserId == null ? '0' : '1',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isCompleted)
            Container(
              width: double.infinity,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '심부름 완료',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else if (canComplete)
            SizedBox(
              width: double.infinity,
              height: 34,
              child: ElevatedButton(
                onPressed: () => _onCompletePressed(item),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFF1F1F1),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  '심부름 완료',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          if (showApplicantNotice) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '새로운 신청자가 ${item.applicantCount}명 있어요!',
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignedCard(ErrandManageItem item) {
    final showScheduleBanner = item.status == 'IN_PROGRESS';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFD4D4D4)),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(item.imageUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatCost(item.cost)}원/${_formatDeadline(item.deadline)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (showScheduleBanner) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _onAddCalendarPressed(item),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '심부름을 맡게 되었어요! 일정에 추가할까요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE57373),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyView(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildList(List<ErrandManageItem> items, bool isRequestedTab) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return _buildEmptyView(
        isRequestedTab ? '부탁한 심부름이 없어요.' : '맡은 심부름이 없어요.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: items.length,
        itemBuilder: (_, index) {
          final item = items[index];
          return isRequestedTab
              ? _buildRequestedCard(item)
              : _buildAssignedCard(item);
        },
      ),
    );
  }

  void _goToCreateScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateErrandsPage()),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF6EE8E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: yellow,
        elevation: 0,
        surfaceTintColor: yellow,
        titleSpacing: 16,
        title: const Text(
          '내 심부름 관리',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.grey,
              indicatorWeight: 1.5,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '내가 부탁한 심부름',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.circle, size: 8, color: Color(0xFFE57373)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '내가 맡은 심부름',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.circle, size: 8, color: Color(0xFFE57373)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_requestedErrands, true),
          _buildList(_assignedErrands, false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateScreen,
        backgroundColor: yellow,
        foregroundColor: Colors.black87,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        label: const Text(
          '+ 글쓰기',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final String itemTitle;

  const _ReviewDialog({required this.itemTitle});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 3;
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade500),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '심부름은 어떠셨나요?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    size: 34,
                    color: Colors.black,
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: '상대방에게 고마운 마음을 전해주세요',
                filled: true,
                fillColor: const Color(0xFFF3F3F3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 110,
                height: 38,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('심부름 완료'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
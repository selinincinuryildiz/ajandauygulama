import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart'; 
import '../../modeller/ajanda_modelleri.dart'; 

class PagePlanlama extends StatefulWidget {
  final List<Etkinlik> events;
  final String filterType; 
  final Function(Etkinlik, bool) onToggleStatus;
  final Function(int) onDelete;
  final Function(Etkinlik) onEdit;
  final VoidCallback onHeaderTap; 

  const PagePlanlama({
    super.key, 
    required this.events, 
    required this.filterType,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onEdit,
    required this.onHeaderTap, 
  });

  @override
  State<PagePlanlama> createState() => _PagePlanlamaState();
}

class _PagePlanlamaState extends State<PagePlanlama> {
  DateTime _selectedDate = DateTime.now(); 
  late ConfettiController _confettiController; 

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _celebrate() {
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    final filteredList = widget.events.where((e) {
      final eventDate = e.baslangicTarihi;
      if (widget.filterType == "Bugün") {
        return eventDate.year == _selectedDate.year && 
               eventDate.month == _selectedDate.month && 
               eventDate.day == _selectedDate.day;
      } else if (widget.filterType == "Hafta") {
        final weekDay = _selectedDate.weekday; 
        final startOfWeek = _selectedDate.subtract(Duration(days: weekDay - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final eDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
        final sDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final endDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
        return eDate.compareTo(sDate) >= 0 && eDate.compareTo(endDate) <= 0;
      } else {
        // AY MODU: Sadece Yıl ve Ay kontrolü (Tüm ayı gösterir)
        return eventDate.year == _selectedDate.year && eventDate.month == _selectedDate.month;
      }
    }).toList();

    String headerText = "Bugün";
    if (widget.filterType == "Bugün") {
      final now = DateTime.now();
      if (_selectedDate.day == now.day && _selectedDate.month == now.month && _selectedDate.year == now.year) {
        headerText = "Bugün";
      } else {
        headerText = DateFormat('d MMMM', 'tr_TR').format(_selectedDate);
      }
    } else if (widget.filterType == "Hafta") {
      headerText = "Bu Hafta";
    } else {
      // Ay modunda sadece Yılı gösterelim (Ayı şeritten seçiyor)
      headerText = "${_selectedDate.year} Planları"; 
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: InkWell(
                onTap: widget.onHeaderTap, 
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    Text(
                      headerText,
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.swap_vert_circle_outlined, color: Colors.grey.withOpacity(0.5), size: 24), 
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            _buildDateStrip(isDark),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Colors.grey), 
            
            Expanded(
              child: filteredList.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        "Planın yok, keyfine bak! ☕", 
                        style: TextStyle(color: Colors.grey[500], fontSize: 16)
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final event = filteredList[index];
                    return _buildSwipeableCard(event, isDark);
                  },
                ),
            ),
          ],
        ),

        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive, 
          shouldLoop: false, 
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple], 
        ),
      ],
    );
  }

  Widget _buildSwipeableCard(Etkinlik event, bool isDark) {
    return Dismissible(
      key: Key(event.id.toString()), 
      
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
      ),

      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),

      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          bool yeniDurum = !event.tamamlandiMi;
          widget.onToggleStatus(event, yeniDurum);
          if (yeniDurum) {
            _celebrate(); 
          }
          return false; 
        } else {
          widget.onDelete(event.id);
          return false; 
        }
      },

      child: _buildEventCard(event, isDark),
    );
  }

  Widget _buildDateStrip(bool isDark) {
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[700];

    // --- YENİ: AY MODUNDA AYLARI LİSTELE ---
    if (widget.filterType == "Ay") {
      return SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: 12, // 12 Ay
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final monthIndex = index + 1;
            final isSelected = monthIndex == _selectedDate.month;
            
            // Ay ismini al (Oca, Şub...)
            final tempDate = DateTime(_selectedDate.year, monthIndex, 1);
            final monthName = DateFormat('MMM', 'tr_TR').format(tempDate);

            return GestureDetector(
              onTap: () {
                setState(() {
                  // Ay modunda seçili tarihi o ayın 1'ine getiriyoruz
                  _selectedDate = DateTime(_selectedDate.year, monthIndex, 1);
                });
              },
              child: Container(
                width: 60, // Aylar için biraz daha geniş kutu
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0055FF).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: const Color(0xFF0055FF), width: 1.5) : null,
                ),
                child: Center(
                  child: Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF0055FF) : secondaryTextColor,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // --- BUGÜN / HAFTA MODUNDA GÜNLERİ LİSTELE ---
    final now = _selectedDate;
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    return SizedBox(
      height: 70, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 7, // 7 Gün
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final date = startOfWeek.add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 48, 
              margin: const EdgeInsets.only(right: 10), 
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0055FF).withOpacity(0.1) : Colors.transparent, 
                borderRadius: BorderRadius.circular(12), 
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'tr_TR').format(date).toUpperCase(), 
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 6), 
                  
                  Text(
                    "${date.day}",
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: isSelected ? (isDark ? Colors.white : Colors.black) : secondaryTextColor,
                    ),
                  ),
                  
                  const SizedBox(height: 6), 

                  if (isSelected)
                    Container(
                      width: 16, 
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0055FF), 
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  else
                    const SizedBox(height: 3),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(Etkinlik event, bool isDark) {
    Color priorityColor = _getPriorityColor(event.oncelik);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;

    String dateText;
    if (widget.filterType == "Bugün") {
      dateText = DateFormat('HH:mm', 'tr_TR').format(event.baslangicTarihi);
    } else {
      dateText = DateFormat('d MMM, HH:mm', 'tr_TR').format(event.baslangicTarihi);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => widget.onEdit(event), 
          child: Padding(
            padding: const EdgeInsets.all(16.0), 
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    bool yeniDurum = !event.tamamlandiMi;
                    widget.onToggleStatus(event, yeniDurum);
                    if(yeniDurum) _celebrate(); 
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: event.tamamlandiMi ? priorityColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: event.tamamlandiMi ? priorityColor : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: event.tamamlandiMi
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ),
                
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.baslik,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600, 
                          color: event.tamamlandiMi ? Colors.grey.shade400 : titleColor,
                          decoration: event.tamamlandiMi ? TextDecoration.lineThrough : null,
                          decorationColor: priorityColor, 
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            dateText,
                            style: TextStyle(
                              color: Colors.grey.shade500, 
                              fontSize: 12, 
                              fontWeight: FontWeight.w500
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.oncelik,
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade300), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  color: cardColor,
                  onSelected: (val) {
                    if (val == 'edit') widget.onEdit(event);
                    if (val == 'delete') widget.onDelete(event.id);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20, color: titleColor),
                          const SizedBox(width: 12),
                          Text("Düzenle", style: TextStyle(fontSize: 14, color: titleColor)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text("Sil", style: TextStyle(color: Colors.red, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Yüksek': return Colors.red;
      case 'Orta': return Colors.orange;
      case 'Düşük': return Colors.green;
      default: return Colors.blue;
    }
  }
}
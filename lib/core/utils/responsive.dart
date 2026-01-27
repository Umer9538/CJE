import 'package:flutter/material.dart';

/// Device type based on screen width
enum DeviceType { mobile, tablet, desktop }

/// Responsive breakpoints following Material Design guidelines
class Breakpoints {
  Breakpoints._();

  /// Mobile: 0 - 599
  static const double mobile = 0;

  /// Tablet: 600 - 1023
  static const double tablet = 600;

  /// Desktop: 1024+
  static const double desktop = 1024;

  /// Large desktop: 1440+
  static const double largeDesktop = 1440;
}

/// Responsive utility class for adaptive layouts
class Responsive {
  final BuildContext context;
  late final Size _size;
  late final double _width;
  late final double _height;

  Responsive(this.context) {
    _size = MediaQuery.of(context).size;
    _width = _size.width;
    _height = _size.height;
  }

  /// Screen width
  double get width => _width;

  /// Screen height
  double get height => _height;

  /// Screen size
  Size get size => _size;

  /// Is mobile device (< 600)
  bool get isMobile => _width < Breakpoints.tablet;

  /// Is tablet device (600 - 1023)
  bool get isTablet => _width >= Breakpoints.tablet && _width < Breakpoints.desktop;

  /// Is desktop device (>= 1024)
  bool get isDesktop => _width >= Breakpoints.desktop;

  /// Is large desktop (>= 1440)
  bool get isLargeDesktop => _width >= Breakpoints.largeDesktop;

  /// Is mobile or tablet
  bool get isMobileOrTablet => _width < Breakpoints.desktop;

  /// Is tablet or desktop
  bool get isTabletOrDesktop => _width >= Breakpoints.tablet;

  /// Current device type
  DeviceType get deviceType {
    if (isDesktop) return DeviceType.desktop;
    if (isTablet) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  /// Get value based on device type
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    if (isTablet && desktop != null) return desktop;
    return mobile;
  }

  /// Calculate responsive padding
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
        horizontal: value(mobile: 16, tablet: 24, desktop: 32),
        vertical: value(mobile: 16, tablet: 20, desktop: 24),
      );

  /// Card padding based on device
  EdgeInsets get cardPadding => EdgeInsets.all(
        value(mobile: 16, tablet: 20, desktop: 24),
      );

  /// Grid column count for list views
  int get gridColumns => value(mobile: 1, tablet: 2, desktop: 3);

  /// Grid column count for cards (more dense)
  int get cardGridColumns => value(mobile: 2, tablet: 3, desktop: 4);

  /// Font scale factor
  double get fontScale => value(mobile: 1.0, tablet: 1.05, desktop: 1.1);

  /// Icon size multiplier
  double get iconScale => value(mobile: 1.0, tablet: 1.15, desktop: 1.25);

  /// Maximum content width for centered layouts
  double get maxContentWidth => value(
        mobile: double.infinity,
        tablet: 720,
        desktop: 1200,
      );

  /// Sidebar width for desktop layouts
  double get sidebarWidth => value(mobile: 0, tablet: 280, desktop: 320);

  /// Bottom nav height
  double get bottomNavHeight => value(mobile: 72, tablet: 80, desktop: 0);

  /// Whether to show sidebar navigation (desktop) vs bottom nav (mobile/tablet)
  bool get useSideNavigation => isDesktop;
}

/// Extension on BuildContext for easy responsive access
extension ResponsiveExtension on BuildContext {
  /// Get responsive helper
  Responsive get responsive => Responsive(this);

  /// Quick device type checks
  bool get isMobile => responsive.isMobile;
  bool get isTablet => responsive.isTablet;
  bool get isDesktop => responsive.isDesktop;
  bool get isTabletOrDesktop => responsive.isTabletOrDesktop;

  /// Screen dimensions
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Orientation
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;
  bool get isPortrait => MediaQuery.of(this).orientation == Orientation.portrait;
}

/// Responsive builder widget for conditional rendering
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Responsive responsive) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, Responsive(context));
  }
}

/// Widget that shows different layouts based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    if (responsive.isDesktop && desktop != null) {
      return desktop!;
    }
    if (responsive.isTablet && tablet != null) {
      return tablet!;
    }
    if (responsive.isTablet && desktop != null) {
      return desktop!;
    }
    return mobile;
  }
}

/// Responsive grid view that adjusts columns based on screen size
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 1.0,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final columns = responsive.value(
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      children: children,
    );
  }
}

/// Centered content container with max width for larger screens
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Alignment alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final effectiveMaxWidth = maxWidth ?? responsive.maxContentWidth;

    Widget content = child;

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (effectiveMaxWidth != double.infinity) {
      content = Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Responsive row that becomes column on mobile
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool reverseOnMobile;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16,
    this.reverseOnMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final effectiveChildren = reverseOnMobile && responsive.isMobile
        ? children.reversed.toList()
        : children;

    if (responsive.isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment == CrossAxisAlignment.center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.stretch,
        children: _addSpacing(effectiveChildren, spacing, Axis.vertical),
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: _addSpacing(effectiveChildren, spacing, Axis.horizontal),
    );
  }

  List<Widget> _addSpacing(List<Widget> widgets, double spacing, Axis axis) {
    if (widgets.isEmpty) return widgets;

    final spacer = axis == Axis.horizontal
        ? SizedBox(width: spacing)
        : SizedBox(height: spacing);

    return widgets.expand((widget) => [widget, spacer]).toList()..removeLast();
  }
}

/// Responsive sized box with different sizes per device
class ResponsiveSizedBox extends StatelessWidget {
  final double? mobileWidth;
  final double? mobileHeight;
  final double? tabletWidth;
  final double? tabletHeight;
  final double? desktopWidth;
  final double? desktopHeight;
  final Widget? child;

  const ResponsiveSizedBox({
    super.key,
    this.mobileWidth,
    this.mobileHeight,
    this.tabletWidth,
    this.tabletHeight,
    this.desktopWidth,
    this.desktopHeight,
    this.child,
  });

  /// Horizontal spacing
  const ResponsiveSizedBox.horizontal({
    super.key,
    double mobile = 8,
    double? tablet,
    double? desktop,
  })  : mobileWidth = mobile,
        tabletWidth = tablet,
        desktopWidth = desktop,
        mobileHeight = null,
        tabletHeight = null,
        desktopHeight = null,
        child = null;

  /// Vertical spacing
  const ResponsiveSizedBox.vertical({
    super.key,
    double mobile = 8,
    double? tablet,
    double? desktop,
  })  : mobileHeight = mobile,
        tabletHeight = tablet,
        desktopHeight = desktop,
        mobileWidth = null,
        tabletWidth = null,
        desktopWidth = null,
        child = null;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    final width = responsive.value(
      mobile: mobileWidth,
      tablet: tabletWidth,
      desktop: desktopWidth,
    );

    final height = responsive.value(
      mobile: mobileHeight,
      tablet: tabletHeight,
      desktop: desktopHeight,
    );

    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    final padding = responsive.value(
      mobile: mobile ?? const EdgeInsets.all(16),
      tablet: tablet,
      desktop: desktop,
    );

    return Padding(padding: padding, child: child);
  }
}

/// Responsive text that scales based on screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    final fontSize = responsive.value(
      mobile: mobileFontSize ?? style?.fontSize ?? 14,
      tablet: tabletFontSize,
      desktop: desktopFontSize,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

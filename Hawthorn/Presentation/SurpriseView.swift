import SwiftUI

/// Home is the three-slot tin. Tag, peel, shake, and clear fuse here. Other desks are sheets.
struct SurpriseView: View {
    @Environment(BarSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if let error = session.catalogError, session.recipes.isEmpty {
                TrayError(line: error, action: "Open the bar") {
                    session.desk = .bar
                }
            } else if let note = session.projection.recoveryNote,
                      session.projection.stowed.isEmpty,
                      session.projection.tin.phase == .bare {
                TrayError(line: note, action: "Open the bar") {
                    session.desk = .bar
                }
            } else if session.projection.stowed.isEmpty && session.projection.tin.phase == .bare {
                EmptyTray(
                    art: "hwt_EmptyHome",
                    headline: "The bar is empty",
                    line: "Add a bottle, then pour.",
                    action: "Open the bar"
                ) {
                    session.desk = .bar
                }
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg)
    }

    private var foldKey: String {
        let ids = session.projection.tin.slots.map(\.bottleID).joined(separator: ",")
        return "\(session.projection.tin.phase.rawValue)|\(ids)|\(session.projection.tin.shakenRecipeID ?? "")"
    }

    /// Phone uses the shorter tin so the wrapped tray, Tag, Shake, and sheet openers share the frame.
    private var populated: some View {
        let compact = sizeClass == .compact
        return ViewThatFits(in: .vertical) {
            homeColumn(compact: compact)
            ScrollView {
                homeColumn(compact: true)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func homeColumn(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? StudioMeasure.unit : StudioMeasure.unit * 2) {
            header
            tinStage(compact: compact)
            tray
            if let note = session.actionError {
                Text(note)
                    .font(StudioMeasure.caption)
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(3)
            }
            if session.projection.tin.phase == .shaken {
                shakenCard
                Button(clearTitle) {
                    Task { await session.clear() }
                }
                .buttonStyle(SoftCardButtonStyle(tone: .quiet))
            }
            if let bottle = session.nextTagBottle {
                Button(tagTitle(bottle.name)) {
                    Task { await session.tag(bottle.id) }
                }
                .buttonStyle(SoftCardButtonStyle())
                .accessibilityLabel(tagTitle(bottle.name))
            }
            Button(session.isShaking ? shakingTitle : shakeTitle) {
                Task { await session.shake() }
            }
            .buttonStyle(SoftCardButtonStyle(tone: session.shakeEnabled ? .primary : .quiet, isLoading: session.isShaking))
            .disabled(!session.shakeEnabled || session.isShaking)
            deskRow
        }
        .padding(.horizontal, StudioMeasure.unit * 2)
        .padding(.top, compact ? StudioMeasure.unit : StudioMeasure.unit * 2)
        .padding(.bottom, compact ? StudioMeasure.unit : StudioMeasure.unit * 2)
    }

    private func tinStage(compact: Bool) -> some View {
        tinCanvas(compact: compact)
            .id(foldKey)
            .transition(.opacity)
            .padding(compact ? 0 : StudioMeasure.unit * 3)
            .frame(
                maxWidth: .infinity,
                minHeight: compact ? nil : StudioMeasure.unit * 28,
                alignment: .top
            )
            .background {
                DriftField(frozen: reduceMotion)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .animation(reduceMotion ? nil : .easeOut(duration: StudioMeasure.fade), value: foldKey)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: StudioMeasure.unit) {
            Text(jobTitle)
                .font(StudioMeasure.display)
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(2)
            Text(session.nextLine)
                .font(StudioMeasure.body)
                .foregroundStyle(DesignTokens.muted)
                .lineLimit(3)
            if let split = session.projection.splitMarks.last, session.projection.tin.phase == .tagged {
                Text(splitLine)
                    .font(StudioMeasure.caption)
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(3)
                    .accessibilityIdentifier("split-\(split.seq)")
            }
        }
    }

    private func tinCanvas(compact: Bool) -> some View {
        let icon = compact ? StudioMeasure.unit * 5 : StudioMeasure.unit * 10
        let pad = compact ? StudioMeasure.unit : StudioMeasure.unit * 2
        return VStack(alignment: .leading, spacing: compact ? StudioMeasure.unit : StudioMeasure.unit * 2) {
            HStack(alignment: .center, spacing: StudioMeasure.unit * 2) {
                Image("hwt_MixingTin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: icon, height: icon)
                    .clipped()
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: StudioMeasure.unit) {
                    Text("Tin")
                        .font(StudioMeasure.headline)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                    Text(taggedCountLine)
                        .font(StudioMeasure.caption)
                        .foregroundStyle(DesignTokens.accent)
                        .lineLimit(1)
                }
            }
            ForEach(0..<TinFold.capacity, id: \.self) { index in
                slotRow(index: index, compact: compact)
            }
        }
        .padding(pad)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(DesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: StudioMeasure.card, style: .continuous))
        .shadow(color: DesignTokens.ink.opacity(0.12), radius: StudioMeasure.shadowBlur, y: StudioMeasure.shadowY)
    }

    private func slotRow(index: Int, compact: Bool) -> some View {
        let slots = session.projection.tin.slots
        let filled = index < slots.count
        let art = compact ? StudioMeasure.unit * 5 : StudioMeasure.unit * 7
        return HStack(spacing: StudioMeasure.unit * 2) {
            Image("hwt_StowedBottle")
                .resizable()
                .scaledToFit()
                .frame(width: filled ? art : art * 0.7, height: art)
                .opacity(filled ? 1 : 0.35)
                .clipped()
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: StudioMeasure.unit / 2) {
                Text(filled ? session.name(for: slots[index].bottleID) : openSeat)
                    .font(filled ? StudioMeasure.headline : StudioMeasure.body)
                    .foregroundStyle(filled ? DesignTokens.ink : DesignTokens.muted)
                    .lineLimit(1)
                Text(filled ? "Tagged" : "Waiting")
                    .font(StudioMeasure.micro)
                    .foregroundStyle(DesignTokens.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: StudioMeasure.unit)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }

    /// Stowed tags wrap onto the next line. Peel is a chip in that same tray, never off the edge.
    private var tray: some View {
        VStack(alignment: .leading, spacing: StudioMeasure.unit) {
            Text(trayCaption)
                .font(StudioMeasure.caption)
                .foregroundStyle(DesignTokens.muted)
                .lineLimit(1)
            TrayFlow(spacing: StudioMeasure.unit) {
                ForEach(trayBottles) { bottle in
                    Button {
                        Task { await session.tag(bottle.id) }
                    } label: {
                        Text(tagTitle(bottle.name))
                            .font(StudioMeasure.caption)
                            .foregroundStyle(DesignTokens.ink)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: true, vertical: true)
                            .padding(.horizontal, StudioMeasure.unit * 2)
                            .frame(minHeight: 44, alignment: .leading)
                            .background(DesignTokens.surface)
                            .clipShape(RoundedRectangle(cornerRadius: StudioMeasure.chip, style: .continuous))
                            .contentShape(RoundedRectangle(cornerRadius: StudioMeasure.chip, style: .continuous))
                    }
                    .accessibilityLabel(tagTitle(bottle.name))
                    .disabled(session.projection.tin.phase == .shaken || session.projection.tin.slots.count >= TinFold.capacity)
                }
                Button {
                    Task { await session.peel() }
                } label: {
                    Text(peelTitle)
                        .font(StudioMeasure.caption)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: true)
                        .padding(.horizontal, StudioMeasure.unit * 2)
                        .frame(minWidth: 44, minHeight: 44)
                        .background(DesignTokens.surface)
                        .clipShape(RoundedRectangle(cornerRadius: StudioMeasure.chip, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: StudioMeasure.chip, style: .continuous))
                }
                .accessibilityLabel("Peel the last slot")
                .disabled(session.projection.tin.slots.isEmpty || session.projection.tin.phase == .shaken)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var shakenCard: some View {
        let recipeID = session.projection.tin.shakenRecipeID
        let recipe = recipeID.flatMap { session.recipe(id: $0) }
        return VStack(alignment: .leading, spacing: StudioMeasure.unit) {
            Text(recipe?.name ?? "Shaken")
                .font(StudioMeasure.title)
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(2)
            Text(methodLine(recipe))
                .font(StudioMeasure.body)
                .foregroundStyle(DesignTokens.muted)
                .lineLimit(4)
            if let recipe {
                let pinned = session.projection.pins.contains(recipe.id)
                Button(pinned ? unpinTitle : pinTitle) {
                    Task {
                        if pinned {
                            await session.unpin(recipe.id)
                        } else {
                            await session.pin(recipe.id)
                        }
                    }
                }
                .buttonStyle(SoftCardButtonStyle(tone: .quiet))
            }
        }
        .padding(StudioMeasure.unit * 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: StudioMeasure.card, style: .continuous))
        .shadow(color: DesignTokens.ink.opacity(0.12), radius: StudioMeasure.shadowBlur, y: StudioMeasure.shadowY)
    }

    private var deskRow: some View {
        VStack(spacing: StudioMeasure.unit) {
            HStack(spacing: StudioMeasure.unit) {
                deskButton("Bar", .bar)
                deskButton("Discover", .discover)
            }
            HStack(spacing: StudioMeasure.unit) {
                deskButton("Favorites", .favorites)
                deskButton("Settings", .settings)
            }
        }
    }

    private func deskButton(_ title: String, _ desk: ReviewLaunch.Desk) -> some View {
        Button {
            session.desk = desk
        } label: {
            Text(title)
                .font(StudioMeasure.caption)
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(DesignTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: StudioMeasure.chip, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: StudioMeasure.chip, style: .continuous))
                .shadow(color: DesignTokens.ink.opacity(0.12), radius: StudioMeasure.shadowBlur, y: StudioMeasure.shadowY)
        }
        .accessibilityLabel(title)
    }

    private var jobTitle: String { "Seat three, then shake." }
    private var splitLine: String { "Split. This trio is not a recipe. Peel one slot and tag a different bottle." }
    private var openSeat: String { "Open slot" }
    private var trayCaption: String { "Stowed, ready to tag" }
    private var peelTitle: String { "Peel" }
    private var shakeTitle: String { "Shake" }
    private var shakingTitle: String { "Shaking" }
    private var clearTitle: String { "Clear the tin" }
    private var pinTitle: String { "Pin this recipe" }
    private var unpinTitle: String { "Unpin" }

    private var taggedCountLine: String {
        let filled = StudioMeasure.count(session.projection.tin.slots.count)
        let cap = StudioMeasure.count(TinFold.capacity)
        return "\(filled) of \(cap) tagged"
    }

    private var trayBottles: [Bottle] {
        let primaryID = session.nextTagBottle?.id
        return session.unseatedStowed.filter { $0.id != primaryID }
    }

    private func tagTitle(_ name: String) -> String { "Tag \(name)" }

    private func methodLine(_ recipe: Recipe?) -> String {
        recipe?.method ?? "The recipe is in the catalog."
    }
}

/// Wraps tray chips onto the next row so a long name stays whole.
private struct TrayFlow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        let rows = pack(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(CGFloat(0)) { $0 + $1.height }
            + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: maxWidth.isFinite ? maxWidth : (rows.map(\.width).max() ?? 0), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = pack(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        var index = 0
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
                index += 1
            }
            y += row.height + spacing
        }
    }

    private struct Item {
        var size: CGSize
    }

    private struct Row {
        var items: [Item] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func pack(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for subview in subviews {
            var size = subview.sizeThatFits(.unspecified)
            if size.width > maxWidth {
                size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
                size.width = min(size.width, maxWidth)
            }
            let nextWidth = row.items.isEmpty ? size.width : row.width + spacing + size.width
            if !row.items.isEmpty, nextWidth > maxWidth + 0.5 {
                rows.append(row)
                row = Row()
            }
            row.items.append(Item(size: size))
            row.width = row.items.count == 1 ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
        }
        if !row.items.isEmpty {
            rows.append(row)
        }
        return rows
    }
}

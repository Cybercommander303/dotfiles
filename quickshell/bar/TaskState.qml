pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool open: false
    property int pending: 0                      // how many tasks are not done yet
    property int doneCount: 0                    // how many are finished
    property alias items: store                  // the list the window displays

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/mybar"

    // qs -c bar ipc call tasks toggle   (also: show, hide)
    IpcHandler {
        target: "tasks"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
    }

    ListModel { id: store }                      // roles: title, done

    FileView {
        id: file
        path: root.dir + "/tasks.json"
        blockLoading: true
        printErrors: false
    }
    Process { id: mkdir; command: ["mkdir", "-p", root.dir] }

    function recount() {
        let n = 0
        for (let i = 0; i < store.count; i++) if (!store.get(i).done) n++
        pending = n
        doneCount = store.count - n
    }

    function load() {
        try {
            const data = JSON.parse(file.text())
            store.clear()
            for (const t of data) store.append({ title: String(t.title), done: !!t.done })
        } catch (e) { }
        recount()
    }

    function save() {
        const out = []
        for (let i = 0; i < store.count; i++) {
            const t = store.get(i)
            out.push({ title: t.title, done: t.done })
        }
        file.setText(JSON.stringify(out, null, 2))
        recount()
    }

    function add(title) {
        const t = title.trim()
        if (t === "") return
        store.insert(0, { title: t, done: false })
        save()
    }

    function toggle(i) {
        const done = !store.get(i).done
        store.setProperty(i, "done", done)
        store.move(i, done ? store.count - 1 : 0, 1)    // finished tasks sink to the bottom
        save()
    }

    function clearDone() {
        for (let i = store.count - 1; i >= 0; i--) if (store.get(i).done) store.remove(i)
        save()
    }

    function remove(i) {
        store.remove(i)
        save()
    }

    Component.onCompleted: { mkdir.running = true; load() }
}

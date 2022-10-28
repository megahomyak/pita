import tkinter
from dataclasses import dataclass
from typing import Sequence, Callable
import os
import random
import time
import threading

root = tkinter.Tk()
root.geometry("800x600")
root.resizable(False, False)


@dataclass
class Element:
    x: int
    y: int
    maker: Callable[[tkinter.Frame], tkinter.Widget]
    width: int = None
    height: int = None


@dataclass
class Screen:
    bg: tkinter.PhotoImage
    is_scrollable: bool
    elements: Sequence[Element] = ()


def screen(img, is_scrollable, elements=()):
    return Screen(bg=tkinter.PhotoImage(file=os.path.join("./images", img)), elements=elements, is_scrollable=is_scrollable)


@dataclass
class TextGetter:
    get: Callable[[], str] = None
    old_text: str = None


def _text_field(frame, getter, show):
    text = tkinter.Entry(frame, show=show)

    if getter is not None:
        def get():
            return text.get()

        getter.get = get

        if getter.old_text is not None:
            text.delete(0, tkinter.END)
            text.insert(tkinter.INSERT, getter.old_text)

    return text


def text_field(getter=None, show=None):
    return lambda frame: _text_field(frame, getter, show)


def text(text):
    return lambda frame: tkinter.Label(frame, text=text)


def _button_command(screen, cb):
    if cb is not None:
        cb()
    if screen:
        load(screen)


def button(text, screen, cb=None):
    return lambda frame: tkinter.Button(frame, text=text, command=lambda: _button_command(screen, cb))


AUTH_BASE = 230


def pair(text_, bias, getter=None, show=None):
    return [Element(x=200, y=AUTH_BASE + bias, maker=text(text_)), Element(x=400, y=AUTH_BASE + bias, maker=text_field(getter, show), width=200)]


sgo_url = TextGetter()
school_name = TextGetter()
username = TextGetter()
password = TextGetter()


def tick_and_load_announcements():
    time.sleep(random.uniform(2, 5))
    show_loading(announcements)


def _show_loading(of_what):
    time.sleep(random.uniform(0.5, 2))
    load(of_what)


def show_loading(of_what):
    load(loading)
    threading.Thread(target=_show_loading, args=(of_what,)).start()


def save_inputs():
    sgo_url.old_text = sgo_url.get()
    school_name.old_text = school_name.get()
    username.old_text = username.get()
    password.old_text = password.get()
    load(auth_loading)
    threading.Thread(target=tick_and_load_announcements).start()


auth = screen("auth.png", is_scrollable=False, elements=[*pair("Ссылка на СГО", 0, sgo_url), *pair("Название школы", 40, school_name), *pair("Имя пользователя", 80, username), *pair("Пароль", 120, password, show="*"), Element(x=350, y=AUTH_BASE + 160, maker=button("Войти", "", save_inputs), width=100)])

auth_loading = screen("auth.png", is_scrollable=False, elements=[*pair("Ссылка на СГО", 0, sgo_url), *pair("Название школы", 40, school_name), *pair("Имя пользователя", 80, username), *pair("Пароль", 120, password, show="*"), Element(x=325, y=AUTH_BASE + 160, maker=text("Подождите..."), width=150)])

announcements = screen("announcements.png", is_scrollable=True, elements=[Element(x=200, y=30, maker=button("Дневник", "", cb=lambda: show_loading("diary")), width=150), Element(x=360, y=30, maker=button("Объявления", "", cb=lambda: show_loading("announcements")))])

loading = screen("loading.png", is_scrollable=False, elements=[Element(x=200, y=30, maker=button("Дневник", "", cb=lambda: show_loading("diary")), width=150), Element(x=325, y=300, maker=text("Загрузка..."), width=150), Element(x=360, y=30, maker=button("Объявления", "", cb=lambda: show_loading("announcements")))])

diary = screen("diary.png", is_scrollable=True, elements=[Element(x=200, y=30, maker=button("Дневник", "", cb=lambda: show_loading("diary")), width=150), Element(x=360, y=30, maker=button("Объявления", "", cb=lambda: show_loading("announcements")))])


loaded = None


def load(screen):
    global loaded
    if loaded is not None:
        loaded.destroy()

    if isinstance(screen, str):
        screen = globals()[screen]

    frame = tkinter.Frame()
    frame.pack(fill="both", expand=True)

    scrollbar = tkinter.Scrollbar(frame)
    if screen.is_scrollable:
        scrollbar.pack(side="right", fill="y")

    canvas = tkinter.Canvas(frame, yscrollcommand=scrollbar.set, scrollregion=(0, 0, screen.bg.width(), screen.bg.height()))
    scrollbar.config(command=canvas.yview)
    canvas.pack(side="left", fill="both", expand=True)

    canvas.create_image(0, 0, image=screen.bg, anchor="nw")

    for element in screen.elements:
        canvas.create_window(element.x, element.y, anchor="nw", window=element.maker(frame), width=element.width, height=element.height)

    loaded = frame


load(auth)
root.mainloop()

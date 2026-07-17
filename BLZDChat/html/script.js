const Chat = {
    isOpen: false,
    isFocused: false,
    messages: [],
    maxMessages: 100,
    maxVisibleMessages: 5,
    fadeTimeout: 12000,
    fadeTimer: null,
    maxInputLength: 256,
    activeChannel: 'global',
    channels: [],
    channelCommands: [],
    suggestions: [],
    emojis: [],
    enableSounds: true,
    enableTimestamps: true,
    enableEmojis: true,
    messageHistory: [],
    historyIndex: -1,
    currentDraft: '',
    selectedSuggestion: -1,
    unreadCounts: {},
    els: {},

    init() {
        this.cacheElements();
        this.bindEvents();
        this.bindNUI();
    },

    cacheElements() {
        this.els = {
            container: document.getElementById('chat-container'),
            messages: document.getElementById('messages'),
            input: document.getElementById('chatInput'),
            inputArea: document.getElementById('inputArea'),
            channelTabs: document.getElementById('channelTabs'),
            sendBtn: document.getElementById('sendBtn'),
            emojiBtn: document.getElementById('emojiBtn'),
            emojiPicker: document.getElementById('emojiPicker'),
            emojiGrid: document.getElementById('emojiGrid'),
            suggestions: document.getElementById('suggestions'),
            charCounter: document.getElementById('charCounter'),
            channelDot: document.getElementById('channelDot'),
            channelLabel: document.getElementById('channelLabel'),
            scrollIndicator: document.getElementById('scrollIndicator'),
            activeChannelIndicator: document.getElementById('activeChannelIndicator'),
        };
    },

    bindEvents() {
        this.els.input.addEventListener('keydown', (e) => this.onKeyDown(e));
        this.els.input.addEventListener('input', () => this.onInput());
        this.els.sendBtn.addEventListener('click', () => this.sendMessage());

        this.els.emojiBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            this.toggleEmojiPicker();
        });

        this.els.activeChannelIndicator.addEventListener('click', () => {
            this.cycleChannel();
        });

        this.els.scrollIndicator.addEventListener('click', () => {
            this.scrollToBottom();
            this.els.scrollIndicator.style.display = 'none';
        });

        this.els.messages.addEventListener('scroll', () => {
            const el = this.els.messages;
            const atBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 40;
            if (atBottom) {
                this.els.scrollIndicator.style.display = 'none';
            }
        });

        document.addEventListener('click', (e) => {
            if (!this.els.emojiPicker.contains(e.target) && e.target !== this.els.emojiBtn) {
                this.els.emojiPicker.style.display = 'none';
            }
        });
    },

    bindNUI() {
        window.addEventListener('message', (event) => {
            const data = event.data;
            switch (data.action) {
                case 'OPEN':
                    this.open();
                    break;
                case 'CLOSE':
                    this.close();
                    break;
                case 'ADD_MESSAGE':
                    this.addMessage(data.message);
                    break;
                case 'CLEAR':
                    this.clearMessages();
                    break;
                case 'INIT':
                    this.configure(data.config);
                    break;
                case 'ADD_SUGGESTION':
                    this.addSuggestion(data.suggestion);
                    break;
                case 'REMOVE_SUGGESTION':
                    this.removeSuggestion(data.command);
                    break;
            }
        });
    },

    configure(config) {
        if (!config) return;

        this.maxMessages = config.maxMessages || 100;
        this.maxVisibleMessages = config.maxVisibleMessages || 5;
        this.fadeTimeout = config.fadeTimeout || 12000;
        this.maxInputLength = config.maxInputLength || 256;
        this.activeChannel = config.defaultChannel || 'global';
        this.channels = config.channels || [];
        this.suggestions = config.suggestions || [];
        this.emojis = config.emojis || [];
        this.enableSounds = config.enableSounds !== false;
        this.enableTimestamps = config.enableTimestamps !== false;
        this.enableEmojis = config.enableEmojis !== false;

        this.channelCommands = [];
        this.channels.forEach((ch) => {
            if (ch.command) {
                this.channelCommands.push(ch.command);
            }
        });

        this.els.input.maxLength = this.maxInputLength;
        this.els.charCounter.textContent = '0/' + this.maxInputLength;

        this.renderChannelTabs();
        this.renderEmojiGrid();
        this.setActiveChannel(this.activeChannel);
        this.applyVisibleLimit();

        if (!this.enableEmojis) {
            this.els.emojiBtn.style.display = 'none';
        }
    },

    renderChannelTabs() {
        this.els.channelTabs.innerHTML = '';

        this.channels.forEach((ch) => {
            const tab = document.createElement('button');
            tab.className = 'channel-tab' + (ch.id === this.activeChannel ? ' active' : '');
            tab.dataset.channel = ch.id;

            tab.innerHTML =
                '<span class="tab-dot" style="background:' + ch.color + '"></span>' +
                '<span>' + ch.label + '</span>' +
                '<span class="unread-badge" id="unread-' + ch.id + '" style="display:none">0</span>';

            tab.addEventListener('click', () => {
                this.setActiveChannel(ch.id);
            });

            this.els.channelTabs.appendChild(tab);
        });
    },

    setActiveChannel(channelId) {
        const channel = this.channels.find(c => c.id === channelId);
        if (!channel) return;

        this.activeChannel = channelId;

        document.querySelectorAll('.channel-tab').forEach(tab => {
            tab.classList.toggle('active', tab.dataset.channel === channelId);
        });

        this.els.channelDot.style.background = channel.color;
        this.els.channelLabel.textContent = channel.label;

        this.unreadCounts[channelId] = 0;
        const badge = document.getElementById('unread-' + channelId);
        if (badge) badge.style.display = 'none';

        this.els.input.placeholder = 'Message in ' + channel.label + '...';
        this.els.input.focus();
    },

    cycleChannel() {
        const switchable = ['global', 'local', 'ooc'];
        const idx = switchable.indexOf(this.activeChannel);
        const next = switchable[(idx + 1) % switchable.length];
        this.setActiveChannel(next);
    },

    open() {
        this.isOpen = true;
        this.isFocused = true;
        this.els.container.classList.remove('hidden', 'faded');
        this.els.container.classList.add('active');
        this.els.inputArea.style.display = 'block';
        this.showAllMessages();
        this.els.input.focus();
        this.clearFadeTimer();
        this.scrollToBottom();
    },

    close() {
        this.isOpen = false;
        this.isFocused = false;
        this.els.container.classList.remove('active');
        this.els.inputArea.style.display = 'none';
        this.els.input.value = '';
        this.els.emojiPicker.style.display = 'none';
        this.els.suggestions.style.display = 'none';
        this.updateCharCounter();
        this.historyIndex = -1;
        this.currentDraft = '';
        this.applyVisibleLimit();
        this.startFadeTimer();

        fetch('https://BLZDChat/close', {
            method: 'POST',
            body: JSON.stringify({})
        });
    },

    showAllMessages() {
        const children = this.els.messages.children;
        for (let i = 0; i < children.length; i++) {
            children[i].style.display = '';
        }
    },

    applyVisibleLimit() {
        const children = this.els.messages.children;
        const total = children.length;
        const limit = this.maxVisibleMessages;

        for (let i = 0; i < total; i++) {
            if (i < total - limit) {
                children[i].style.display = 'none';
            } else {
                children[i].style.display = '';
            }
        }
    },

    setFaded(faded) {
        this.els.container.classList.toggle('faded', faded);
    },

    startFadeTimer() {
        this.clearFadeTimer();
        this.setFaded(false);
        this.fadeTimer = setTimeout(() => {
            if (!this.isFocused) {
                this.setFaded(true);
            }
        }, this.fadeTimeout);
    },

    clearFadeTimer() {
        if (this.fadeTimer) {
            clearTimeout(this.fadeTimer);
            this.fadeTimer = null;
        }
        this.setFaded(false);
    },

    addMessage(msg) {
        msg.type = msg.type || 'normal';
        msg.channel = msg.channel || 'global';
        msg.timestamp = msg.timestamp || this.getTimestamp();

        this.messages.push(msg);

        while (this.messages.length > this.maxMessages) {
            this.messages.shift();
            if (this.els.messages.firstChild) {
                this.els.messages.removeChild(this.els.messages.firstChild);
            }
        }

        const el = this.renderMessage(msg);
        this.els.messages.appendChild(el);

        if (this.isOpen) {
            this.showAllMessages();
        } else {
            this.applyVisibleLimit();
        }

        const messagesEl = this.els.messages;
        const atBottom = messagesEl.scrollHeight - messagesEl.scrollTop - messagesEl.clientHeight < 80;

        if (atBottom || this.isFocused) {
            this.scrollToBottom();
        } else {
            this.els.scrollIndicator.style.display = 'block';
        }

        if (!this.isFocused && msg.channel !== this.activeChannel) {
            this.unreadCounts[msg.channel] = (this.unreadCounts[msg.channel] || 0) + 1;
            const badge = document.getElementById('unread-' + msg.channel);
            if (badge) {
                badge.textContent = this.unreadCounts[msg.channel];
                badge.style.display = 'inline';
            }
        }

        if (this.enableSounds && !this.isFocused && msg.type !== 'system') {
            this.playSound();
        }

        this.els.container.classList.remove('hidden');
        this.startFadeTimer();
    },

    renderMessage(msg) {
        const el = document.createElement('div');
        el.className = 'message type-' + msg.type;

        let html = '';

        if (this.enableTimestamps) {
            html += '<span class="timestamp">' + msg.timestamp + '</span>';
        }

        html += '<div class="msg-body">';

        if (msg.channelLabel && msg.channel !== this.activeChannel) {
            html += '<span class="channel-tag" style="background:' +
                this.hexToRgba(msg.channelColor || '#8B5CF6', 0.15) +
                '; color:' + (msg.channelColor || '#8B5CF6') + '">' +
                msg.channelLabel + '</span>';
        }

        if (msg.roleLabel) {
            html += '<span class="role-badge" style="background:' +
                this.hexToRgba(msg.roleColor || '#6B7280', 0.2) +
                '; color:' + (msg.roleColor || '#6B7280') + '">' +
                msg.roleLabel + '</span>';
        }

        if (msg.author && msg.type !== 'system' && msg.type !== 'error' && msg.type !== 'success') {
            const authorColor = msg.color || '#F1F5F9';

            if (msg.type === 'action') {
                html += '<span class="msg-text"><span class="msg-author" style="color:' +
                    authorColor + '">' + this.escapeHTML(msg.author) +
                    '</span> ' + this.formatText(msg.text) + '</span>';
            } else {
                html += '<span class="msg-author" style="color:' +
                    authorColor + '">' + this.escapeHTML(msg.author) +
                    ':</span> <span class="msg-text">' +
                    this.formatText(msg.text) + '</span>';
            }
        } else {
            html += '<span class="msg-text">' + this.formatText(msg.text) + '</span>';
        }

        html += '</div>';
        el.innerHTML = html;
        return el;
    },

    clearMessages() {
        this.messages = [];
        this.els.messages.innerHTML = '';
    },

    onKeyDown(e) {
        switch (e.key) {
            case 'Enter':
                e.preventDefault();
                if (this.els.input.value.trim() === '') {
                    this.close();
                } else {
                    this.sendMessage();
                }
                break;
            case 'Escape':
                e.preventDefault();
                this.close();
                break;
            case 'ArrowUp':
                e.preventDefault();
                this.navigateHistory(1);
                break;
            case 'ArrowDown':
                e.preventDefault();
                this.navigateHistory(-1);
                break;
            case 'Tab':
                e.preventDefault();
                this.applySuggestion();
                break;
        }
    },

    onInput() {
        this.updateCharCounter();
        this.updateSuggestions();
    },

    sendMessage() {
        const text = this.els.input.value.trim();
        if (!text) {
            this.close();
            return;
        }

        this.messageHistory.unshift(text);
        if (this.messageHistory.length > 50) {
            this.messageHistory.pop();
        }
        this.historyIndex = -1;

        let channel = this.activeChannel;
        let processedText = text;

        for (const ch of this.channels) {
            if (ch.command && text.toLowerCase().startsWith(ch.command + ' ')) {
                channel = ch.id;
                processedText = text.substring(ch.command.length + 1).trim();
                break;
            } else if (ch.command && text.toLowerCase() === ch.command) {
                channel = ch.id;
                processedText = '';
                break;
            }
        }

        fetch('https://BLZDChat/sendMessage', {
            method: 'POST',
            body: JSON.stringify({
                text: processedText,
                rawText: text,
                channel: channel,
                channels: this.channelCommands,
            })
        });

        this.els.input.value = '';
        this.updateCharCounter();
        this.els.suggestions.style.display = 'none';
        this.close();
    },

    navigateHistory(direction) {
        if (direction === -1 && this.historyIndex === -1 && this.els.input.value.trim() !== '') {
            this.currentDraft = this.els.input.value;
        }

        this.historyIndex += direction;

        if (this.historyIndex < -1) {
            this.historyIndex = -1;
        }

        if (this.historyIndex === -1) {
            this.els.input.value = this.currentDraft || '';
            this.updateCharCounter();
            return;
        }

        if (this.historyIndex >= this.messageHistory.length) {
            this.historyIndex = this.messageHistory.length - 1;
            return;
        }

        this.els.input.value = this.messageHistory[this.historyIndex];
        this.updateCharCounter();
        this.updateSuggestions();

        const input = this.els.input;
        setTimeout(() => {
            input.selectionStart = input.selectionEnd = input.value.length;
        }, 0);
    },

    addSuggestion(sug) {
        const exists = this.suggestions.find(s => s.command === sug.command);
        if (!exists) {
            this.suggestions.push(sug);
        }
    },

    removeSuggestion(command) {
        this.suggestions = this.suggestions.filter(s => s.command !== command);
    },

    updateSuggestions() {
        const text = this.els.input.value;

        if (!text.startsWith('/')) {
            this.els.suggestions.style.display = 'none';
            this.selectedSuggestion = -1;
            return;
        }

        const matches = this.suggestions.filter(s =>
            s.command.toLowerCase().startsWith(text.toLowerCase().split(' ')[0])
        );

        if (matches.length === 0) {
            this.els.suggestions.style.display = 'none';
            this.selectedSuggestion = -1;
            return;
        }

        this.els.suggestions.innerHTML = '';

        matches.forEach((s, idx) => {
            const item = document.createElement('div');
            item.className = 'suggestion-item' + (idx === this.selectedSuggestion ? ' selected' : '');

            let paramsHtml = '';
            if (s.params && s.params.length > 0) {
                paramsHtml = '<div class="sug-params">' +
                    s.params.map(p => '<span class="sug-param">' + p.name + '</span>').join('') +
                    '</div>';
            }

            item.innerHTML =
                '<span class="sug-command">' + s.command + '</span>' +
                '<span class="sug-desc">' + s.description + '</span>' +
                paramsHtml;

            item.addEventListener('click', () => {
                this.els.input.value = s.command + ' ';
                this.els.input.focus();
                this.updateSuggestions();
            });

            this.els.suggestions.appendChild(item);
        });

        this.els.suggestions.style.display = 'block';
    },

    applySuggestion() {
        const items = this.els.suggestions.querySelectorAll('.suggestion-item');
        if (items.length === 0) return;

        this.selectedSuggestion = Math.max(0, this.selectedSuggestion);
        if (this.selectedSuggestion >= items.length) {
            this.selectedSuggestion = 0;
        }

        const command = items[this.selectedSuggestion].querySelector('.sug-command').textContent;
        this.els.input.value = command + ' ';
        this.els.input.focus();
        this.els.suggestions.style.display = 'none';
    },

    renderEmojiGrid() {
        this.els.emojiGrid.innerHTML = '';
        this.emojis.forEach(emoji => {
            const btn = document.createElement('button');
            btn.className = 'emoji-item';
            btn.textContent = emoji;
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                this.insertEmoji(emoji);
            });
            this.els.emojiGrid.appendChild(btn);
        });
    },

    toggleEmojiPicker() {
        const visible = this.els.emojiPicker.style.display === 'block';
        this.els.emojiPicker.style.display = visible ? 'none' : 'block';
    },

    insertEmoji(emoji) {
        const input = this.els.input;
        const pos = input.selectionStart;
        const val = input.value;

        if (val.length + emoji.length > this.maxInputLength) return;

        input.value = val.substring(0, pos) + emoji + val.substring(pos);
        input.focus();
        input.selectionStart = input.selectionEnd = pos + emoji.length;
        this.updateCharCounter();
    },

    updateCharCounter() {
        const len = this.els.input.value.length;
        this.els.charCounter.textContent = len + '/' + this.maxInputLength;

        this.els.charCounter.classList.remove('warning', 'danger');
        if (len > this.maxInputLength * 0.9) {
            this.els.charCounter.classList.add('danger');
        } else if (len > this.maxInputLength * 0.75) {
            this.els.charCounter.classList.add('warning');
        }
    },

    scrollToBottom() {
        requestAnimationFrame(() => {
            this.els.messages.scrollTop = this.els.messages.scrollHeight;
        });
    },

    getTimestamp() {
        const now = new Date();
        return now.getHours().toString().padStart(2, '0') + ':' +
               now.getMinutes().toString().padStart(2, '0');
    },

    escapeHTML(str) {
        const div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    },

    formatText(text) {
        if (!text) return '';
        let formatted = this.escapeHTML(text);
        formatted = formatted.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
        formatted = formatted.replace(/\*(.*?)\*/g, '<em>$1</em>');
        formatted = formatted.replace(/__(.*?)__/g, '<u>$1</u>');
        formatted = formatted.replace(/`(.*?)`/g, '<code style="background:rgba(139,92,246,0.15);padding:1px 5px;border-radius:3px;font-size:11px;">$1</code>');
        formatted = formatted.replace(/(https?:\/\/[^\s<]+)/g, '<a href="$1" target="_blank">$1</a>');
        return formatted;
    },

    hexToRgba(hex, alpha) {
        if (!hex) return 'rgba(100,100,100,' + alpha + ')';
        hex = hex.replace('#', '');
        if (hex.length === 3) {
            hex = hex.split('').map(c => c + c).join('');
        }
        const r = parseInt(hex.substring(0, 2), 16);
        const g = parseInt(hex.substring(2, 4), 16);
        const b = parseInt(hex.substring(4, 6), 16);
        return 'rgba(' + r + ',' + g + ',' + b + ',' + alpha + ')';
    },

    playSound() {
        try {
            const audio = document.getElementById('notifSound');
            if (audio) {
                audio.currentTime = 0;
                audio.volume = 0.3;
                audio.play().catch(() => {});
            }
        } catch (e) {}
    }
};

document.addEventListener('DOMContentLoaded', () => {
    Chat.init();
});
package main

import (
	"log"

	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api"
)

func init() {
	fetch_tasks()
}

func main() {
	bot, bot_err := tgbotapi.NewBotAPI("Your very secret API key")
	if bot_err != nil {
		log.Panic(bot_err)
	}

	u := tgbotapi.NewUpdate(0)
	u.Timeout = 60

	updates, updates_err := bot.GetUpdatesChan(u)
	if updates_err != nil {
		log.Panic(updates_err)
	}

	for update := range updates {
		if update.Message != nil {
			msg := tgbotapi.NewMessage(update.Message.Chat.ID, "")
			msg.Text = get_response(update)
			bot.Send(msg)
		}
	}
}

package main

import (
	"crypto/tls"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"

	flags "github.com/jessevdk/go-flags"
)

type opts struct {
	Target            string      `long:"target" short:"t"`
	Username          string      `long:"username" short:"u"`
	Password          string      `long:"password" short:"p"`
	SkipSSLValidation bool        `long:"skip-ssl-validation" short:"k"`
	Curl              CurlCommand `command:"curl"`
}

var o opts

type CurlCommand struct {
	Path   string `long:"path" short:"p"`
	Silent bool   `long:"silent" short:"s"`
}

func (c *CurlCommand) Execute(args []string) error {
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: o.SkipSSLValidation,
		},
	}
	client := &http.Client{Transport: tr}
	resp, err := client.Get(fmt.Sprintf("%s%s", o.Target, c.Path))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	io.Copy(os.Stdout, resp.Body)
	return nil
}

func main() {
	_, err := flags.Parse(&o)
	if err != nil {
		log.Fatalf("error: %s\n", err)
	}
}

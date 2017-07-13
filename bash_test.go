package pcf_pipelines_test

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
	"github.com/onsi/gomega/gexec"
	"github.com/onsi/gomega/ghttp"
)

var _ = Describe("bash tests", func() {
	Context("allow-only-patch-upgrades", func() {
		var (
			command *exec.Cmd
			session *gexec.Session
			tmpDir  string
			server  *ghttp.Server
		)

		BeforeEach(func() {
			var err error
			tmpDir, err = ioutil.TempDir("", "bash-test")
			Expect(err).NotTo(HaveOccurred())
			err = ioutil.WriteFile(filepath.Join(tmpDir, "version"), []byte("1.11.3"), os.ModePerm)
			Expect(err).NotTo(HaveOccurred())

			command = exec.Command("bash", "-c", "tasks/allow-only-patch-upgrades/task.sh")
			env := os.Environ()
			for i := range env {
				if strings.HasPrefix(env[i], "PATH=") {
					path := strings.Split(env[i], "=")[1]
					env[i] = fmt.Sprintf("PATH=%s:%s", filepath.Dir(om_linux_path), path)
				}
			}

			server = ghttp.NewTLSServer()

			taskEnv := []string{
				fmt.Sprintf("OPSMAN_URI=%s", strings.TrimPrefix(server.URL(), "https://")),
				"OPSMAN_USERNAME=some-username",
				"OPSMAN_PASSWORD=some-password",
				"PRODUCT_NAME=some-product-name",
				fmt.Sprintf("PRODUCT_FILES_DIR=%s", tmpDir),
			}
			command.Env = append(env, taskEnv...)
		})

		JustBeforeEach(func() {
			var err error
			session, err = gexec.Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).NotTo(HaveOccurred())
		})

		AfterEach(func() {
			os.RemoveAll(tmpDir)
			server.Close()
		})

		Context("when the deployed product is of the same minor version as the downloaded product file", func() {
			BeforeEach(func() {
				server.AppendHandlers(
					ghttp.CombineHandlers(
						ghttp.VerifyRequest("GET", "/api/v0/deployed/products"),
						ghttp.RespondWith(http.StatusOK, `[
						{
							"installation_name":"p-bosh",
							"guid":"p-bosh-9c60538f074d2fcad102",
							"type":"some-other-product-name",
							"product_version":"1.11.3.0"
						},
						{
							"installation_name":"cf-c35302beebdb56a73f85",
							"guid":"cf-c35302beebdb56a73f85",
							"type":"some-product-name",
							"product_version":"1.11.1"
						}
					]`),
					),
				)
			})

			It("requests deployed products from the server", func() {
				Eventually(server.ReceivedRequests).Should(HaveLen(1))
				session.Wait()
			})

			It("exits 0", func() {
				session.Wait()
				Expect(session.ExitCode()).To(Equal(0))
			})

			It("prints a successful message", func() {
				Eventually(session.Out).Should(gbytes.Say("we have a safe upgrade for version: 1.11"))
				session.Wait()
			})

		})

		Context("when the deployed product is of a different minor version than the downloaded product file", func() {
			BeforeEach(func() {
				server.AppendHandlers(
					ghttp.CombineHandlers(
						ghttp.VerifyRequest("GET", "/api/v0/deployed/products"),
						ghttp.RespondWith(http.StatusOK, `[
						{
							"installation_name":"p-bosh",
							"guid":"p-bosh-9c60538f074d2fcad102",
							"type":"some-other-product-name",
							"product_version":"1.11.3.0"
						},
						{
							"installation_name":"cf-c35302beebdb56a73f85",
							"guid":"cf-c35302beebdb56a73f85",
							"type":"some-product-name",
							"product_version":"1.12.1"
						}
					]`),
					),
				)
			})

			It("requests deployed products from the server", func() {
				Eventually(server.ReceivedRequests).Should(HaveLen(1))
				session.Wait()
			})

			It("exits 1", func() {
				session.Wait()
				Expect(session.ExitCode()).To(Equal(1))
			})

			It("prints a helpful error message", func() {
				Eventually(session.Out.Contents).Should(ContainSubstring(`To upgrade patch releases, we suggest using the following version regex in your params file:
^1\.12\..*$`))
				session.Wait()
			})
		})

		Context("when the deployed product is the same exact version as the new one", func() {
			BeforeEach(func() {
				server.AppendHandlers(
					ghttp.CombineHandlers(
						ghttp.VerifyRequest("GET", "/api/v0/deployed/products"),
						ghttp.RespondWith(http.StatusOK, `[
						{
							"installation_name":"p-bosh",
							"guid":"p-bosh-9c60538f074d2fcad102",
							"type":"some-other-product-name",
							"product_version":"1.11.3.0"
						},
						{
							"installation_name":"cf-c35302beebdb56a73f85",
							"guid":"cf-c35302beebdb56a73f85",
							"type":"some-product-name",
							"product_version":"1.11.3"
						}
					]`),
					),
				)
			})

			It("requests deployed products from the server", func() {
				Eventually(server.ReceivedRequests).Should(HaveLen(1))
				session.Wait()
			})

			It("exits 1", func() {
				session.Wait()
				Expect(session.ExitCode()).To(Equal(1))
			})

			It("prints a helpful error message", func() {
				Eventually(session.Out.Contents).Should(ContainSubstring("You are attempting to install a version that is already installed: 1.11.3"))
				session.Wait()
			})
		})
	})
})

package pcf_pipelines_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gexec"

	"testing"
)

func TestPcfPipelines(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "PcfPipelines Suite")
}

var om_linux_path string

var _ = SynchronizedBeforeSuite(func() []byte {
	path, err := gexec.Build("./ci/cmd/om-linux")
	Expect(err).NotTo(HaveOccurred())
	return []byte(path)
}, func(data []byte) {
	om_linux_path = string(data)
})

var _ = SynchronizedAfterSuite(func() {}, func() {
	gexec.CleanupBuildArtifacts()
})

I’ve been working with the ‘big three’ cloud providers (AWS, Azure and
Google) for many years; I’ve had a VPC and an EC2 instance up in AWS for
at least 6, and worked on lots of projects in Azure. But I’ve never
taken the time to *really* do some structured study on any of these. So
it’s time to remedy this.

But why learn each cloud provider individually? There’s so much overlap
in functionality between the big three that I think it makes more sense
to learn each of them in parallel. You also get to contrast them against
each other, and find the situations in which one may do something in a
better way than the other.

I’m also a big advocate of automation (where it makes sense), and the
thought of trying to learn by pointing and clicking through a portal
immediately makes me want to turn off my laptop. So all of the scenarios
will spun up (and down) using infrastructure-as-code, preferably using
[Terraform](https://terraform.io), and where that’s not possible using
the providers’ CLI tools.

# How It’s Structured

Each chapter on this book will focus on high’ish level concept (basic
networking, DNS, serverless). Within each chapter we will create a
number of different scenarios that apply to this concept. I’ll link to
the Terraform code that creates the scenario, and we will also run
through some tests to prove out the operational status. For example we
might ping outbound from an EC2 instance, make an HTTP request to a load
balancer, or a DNS request to a DNS server.

# How It’s Generated

Each page is generated from an Rmarkdown document, with inline code
being ‘knitted’ into the document using the
[knitr](https://yihui.org/knitr/) package. This is similar to Jupyter
notebooks, however as an advocate of R I would say it’s more powerful.

The generated markdown, along with the Terraform files for each
scenario, and any other secondary files, and commited and pushed up to a
[github repository](https://github.com/gregfoletta/big_three/). This
repository is linked with a gitbooks site called
[bigthree.study.foletta.org](https://bigthree.study.foletta.org/).
Whenever a new commit is pushed, this gitbooks site is auto-generated
from the markdown files.

# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import std/options
import std/strutils
import std/json

import emailparser
test "does not crash":
  discard envelope_to_jmap("")

test "parses email":
  let res = envelope_to_jmap("""
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/simple; d=ietf.org; s=ietf1;
	t=1636520096; bh=9uzL67Zcpf9sZemgFCdO8L9XlW/U4Dl+Qg8Kxs5YdYM=;
	h=To:Date:From:Subject:List-Id:List-Unsubscribe:List-Archive:
	 List-Post:List-Help:List-Subscribe;
	b=CCDCUJ8PP+r+YqLVqf/af/pE6B9+zN8P+ida1J7cGPmd7LamrFPi2HPaGf8sDVOnm
	 Pp9FIAiImI82vhHJFFZVCcnLq7nL3zwMxweT/1yhjWG/hk4b5OCbGlE6G6t+BQy+bn
	 fZCToyNY2q9b+qYi+YHSlApuGvqkS/d12Z/1yrPY=
X-Mailbox-Line: From jmap-bounces@ietf.org  Tue Nov  9 20:54:51 2021
Received: from ietfa.amsl.com (localhost [IPv6:::1])
	by ietfa.amsl.com (Postfix) with ESMTP id 2BFCD3A1205;
	Tue,  9 Nov 2021 20:54:50 -0800 (PST)
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/simple; d=ietf.org; s=ietf1;
	t=1636520090; bh=9uzL67Zcpf9sZemgFCdO8L9XlW/U4Dl+Qg8Kxs5YdYM=;
	h=To:Date:From:Subject:List-Id:List-Unsubscribe:List-Archive:
	 List-Post:List-Help:List-Subscribe;
	b=gyjhURj7+N4uE3cvlffWp69U9bvWKqMDSFf5KWJJ0I92UwB7zywafiMLH3MWzdLXk
	 Z9dkQzEMbjj0wRPA5ESiu4k3aufTGLAF2PHpiOyXlhYiiEuVKBfFnGdhvnlva4hU46
	 dyNrAzB/Q7sQvFO7V9vPa2mnjOdU4+jBSFY5LAfg=
X-Original-To: jmap@ietf.org
Received: from ietfa.amsl.com (localhost [IPv6:::1])
 by ietfa.amsl.com (Postfix) with ESMTP id 373A93A11FB
 for <jmap@ietf.org>; Tue,  9 Nov 2021 20:54:47 -0800 (PST)
MIME-Version: 1.0
To: <jmap@ietf.org>
X-Test-IDTracker: no
X-IETF-IDTracker: 7.39.0
Auto-Submitted: auto-generated
Precedence: bulk
Message-ID: <163652008720.30366.8735625437093867106@ietfa.amsl.com>
Date: Tue, 09 Nov 2021 20:54:47 -0800
From: IETF Secretariat <ietf-secretariat-reply@ietf.org>
Archived-At: <https://mailarchive.ietf.org/arch/msg/jmap/9owcWuO7mjg2JMMzI_lZ1N5t0Lg>
Subject: [Jmap] Milestones changed for jmap WG
X-BeenThere: jmap@ietf.org
X-Mailman-Version: 2.1.29
List-Id: JSON Message Access Protocol <jmap.ietf.org>
List-Unsubscribe: <https://www.ietf.org/mailman/options/jmap>,
 <mailto:jmap-request@ietf.org?subject=unsubscribe>
List-Archive: <https://mailarchive.ietf.org/arch/browse/jmap/>
List-Post: <mailto:jmap@ietf.org>
List-Help: <mailto:jmap-request@ietf.org?subject=help>
List-Subscribe: <https://www.ietf.org/mailman/listinfo/jmap>,
 <mailto:jmap-request@ietf.org?subject=subscribe>
Content-Type: text/plain; charset="us-ascii"
Content-Transfer-Encoding: 7bit
Errors-To: jmap-bounces@ietf.org
Sender: "Jmap" <jmap-bounces@ietf.org>
Authentication-Results: ellomb.netlib.re;
	dkim=pass header.d=ietf.org header.s=ietf1 header.b=CCDCUJ8P;
	dkim=pass header.d=ietf.org header.s=ietf1 header.b=gyjhURj7;
	dmarc=pass (policy=none) header.from=ietf.org;
	spf=pass (ellomb.netlib.re: domain of jmap-bounces@ietf.org designates 4.31.198.44 as permitted sender) smtp.mailfrom=jmap-bounces@ietf.org
X-Spamd-Bar: -------

Changed milestone "Submit SMIME Sender Extensions document to the IESG", set
state to active from review, accepting new milestone.

URL: https://datatracker.ietf.org/wg/jmap/about/

_______________________________________________
Jmap mailing list
Jmap@ietf.org
https://www.ietf.org/mailman/listinfo/jmap
""".replace("\n", "\r\n"))
  assert res.is_some
  let email = res.get
  echo email.pretty
  assert email["to"][0]["email"].get_str == "jmap@ietf.org"
  assert email["to"][0]["name"].kind == JNull
  assert email["subject"].get_str == "[Jmap] Milestones changed for jmap WG"

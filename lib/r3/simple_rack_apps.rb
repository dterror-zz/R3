module R3
  
  module SimpleRackApps
    HiApp = Proc.new do |env|
      [200,
        {'Content-Type' => 'text/plain', 'Content-Length' => '2' },
        ["Hi"]
        ]
    end
  
    HelloApp = Proc.new do |env|
      [200,
        {'Content-Type' => 'text/plain', 'Content-Length' => '5' },
        ["Hello"]
        ]
    end
  end
end
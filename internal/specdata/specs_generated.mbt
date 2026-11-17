// Generated from hash-verified official fixtures; used only by conformance tools.

///|
let fixture_01 : String =
  #|{
  #|    "name": "01-simple-examples",
  #|    "state": {
  #|        "version": 1,
  #|        "features": [
  #|            {
  #|                "name": "Feature.A",
  #|                "description": "Enabled toggle",
  #|                "enabled": true,
  #|                "strategies": [{
  #|                    "name": "default"
  #|                }]
  #|            },
  #|            {
  #|                "name": "Feature.B",
  #|                "description": "Disabled toggle",
  #|                "enabled": false,
  #|                "strategies": [{
  #|                    "name": "default"
  #|                }]
  #|            },
  #|            {
  #|                "name": "Feature.C",
  #|                "enabled": true,
  #|                "strategies": []
  #|            }
  #|        ]
  #|    },
  #|    "tests": [
  #|        {
  #|            "description": "Feature.A should be enabled",
  #|            "context": {},
  #|            "toggleName": "Feature.A",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.B should be disabled",
  #|            "context": {},
  #|            "toggleName": "Feature.B",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.C should be enabled when strategy missing",
  #|            "context": {},
  #|            "toggleName": "Feature.C",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Unknown feature toggle should be disabled",
  #|            "context": {},
  #|            "toggleName": "Unknown",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Should allow all context values",
  #|            "context": {
  #|                "userId": "123",
  #|                "sessionId": "asd123",
  #|                "remoteAddress": "127.0.0.1",
  #|                "properties": {
  #|                    "customName": "customValue",
  #|                    "anotherName": "anotherValue"
  #|                }
  #|            },
  #|            "toggleName": "Feature.A",
  #|            "expectedResult": true
  #|        }
  #|    ]
  #|}

///|
let fixture_02 : String =
  #|{
  #|  "name": "02-user-with-id-strategy",
  #|  "state": {
  #|    "version": 1,
  #|    "features": [
  #|      {
  #|        "name": "Feature.A2",
  #|        "description": "Enabled toggle",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "userWithId",
  #|            "parameters": {
  #|              "userIds": "123"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.B2",
  #|        "description": "Disabled toggle",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "userWithId",
  #|            "parameters": {
  #|              "userIds": "123"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.C2",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "userWithId",
  #|            "parameters": {
  #|              "userIds": "123"
  #|            }
  #|          },
  #|          {
  #|            "name": "default"
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.D2",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "userWithId",
  #|            "parameters": {
  #|              "userIds": "123, 222, 88"
  #|            }
  #|          }
  #|        ]
  #|      }
  #|    ]
  #|  },
  #|  "tests": [
  #|    {
  #|      "description": "Feature.A2 Should be enabled for user on context",
  #|      "context": {
  #|        "userId": "123"
  #|      },
  #|      "toggleName": "Feature.A2",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.A2 Should not be enabled for user not in context",
  #|      "context": {
  #|        "userId": "22"
  #|      },
  #|      "toggleName": "Feature.A2",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Feature.C2 Should not be enabled for for everyone",
  #|      "context": {
  #|        "userId": "22"
  #|      },
  #|      "toggleName": "Feature.C2",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.D2 Should not be enabled for user in list",
  #|      "context": {
  #|        "userId": "222"
  #|      },
  #|      "toggleName": "Feature.D2",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.A2 Should be disabled when no userId on context",
  #|      "context": {},
  #|      "toggleName": "Feature.A2",
  #|      "expectedResult": false
  #|    }
  #|  ]
  #|}

///|
let fixture_03 : String =
  #|{
  #|  "name": "03-gradual-rollout-user-id-strategy",
  #|  "state": {
  #|    "version": 1,
  #|    "features": [
  #|      {
  #|        "name": "Feature.A3",
  #|        "description": "Enabled toggle for 100%",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutUserId",
  #|            "parameters": {
  #|              "percentage": "100",
  #|              "groupId": "AB12A"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.B3",
  #|        "description": "Enabled toggle for 50%",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutUserId",
  #|            "parameters": {
  #|              "percentage": "50",
  #|              "groupId": "AB12A"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.C3",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutUserId",
  #|            "parameters": {
  #|              "percentage": "0",
  #|              "groupId": "AB12A"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.D3",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutUserId",
  #|            "parameters": {
  #|              "percentage": "0",
  #|              "groupId": "AB12A"
  #|            }
  #|          },
  #|          {
  #|            "name": "default"
  #|          }
  #|        ]
  #|      }
  #|    ]
  #|  },
  #|  "tests": [
  #|    {
  #|      "description": "Feature.A3 should be enabled for user on context",
  #|      "context": {
  #|        "userId": "123"
  #|      },
  #|      "toggleName": "Feature.A3",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.A3 should be disabled when no user on context",
  #|      "context": {},
  #|      "toggleName": "Feature.A3",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Feature.B3 should be enabled for userId=122",
  #|      "context": {
  #|        "userId": "122"
  #|      },
  #|      "toggleName": "Feature.B3",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.B3 should be disabled for userId=155",
  #|      "context": {
  #|        "userId": "155"
  #|      },
  #|      "toggleName": "Feature.B3",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Feature.C3 should be disabled",
  #|      "context": {
  #|        "userId": "122"
  #|      },
  #|      "toggleName": "Feature.C3",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Feature.D3 should be enabled for all because of default strategy",
  #|      "context": {},
  #|      "toggleName": "Feature.D3",
  #|      "expectedResult": true
  #|    }
  #|  ]
  #|}

///|
let fixture_04 : String =
  #|{
  #|  "name": "04-gradual-rollout-session-id-strategy",
  #|  "state": {
  #|    "version": 1,
  #|    "features": [
  #|      {
  #|        "name": "Feature.A4",
  #|        "description": "Enabled toggle for 100%",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutSessionId",
  #|            "parameters": {
  #|              "percentage": "100",
  #|              "groupId": "AB12A"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.B4",
  #|        "description": "Enabled toggle for 50%",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutSessionId",
  #|            "parameters": {
  #|              "percentage": "50",
  #|              "groupId": "AB12A"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.C4",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutSessionId",
  #|            "parameters": {
  #|              "percentage": "0",
  #|              "groupId": "AB12A"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.D4",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutSessionId",
  #|            "parameters": {
  #|              "percentage": "0",
  #|              "groupId": "AB12A"
  #|            }
  #|          },
  #|          {
  #|            "name": "default"
  #|          }
  #|        ]
  #|      }
  #|    ]
  #|  },
  #|  "tests": [
  #|    {
  #|      "description": "Feature.A4 should be enabled for user on context",
  #|      "context": {
  #|        "sessionId": "123"
  #|      },
  #|      "toggleName": "Feature.A4",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.A4 should be disabled when no user on context",
  #|      "context": {},
  #|      "toggleName": "Feature.A4",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Feature.B4 should be enabled for sessionId=122",
  #|      "context": {
  #|        "sessionId": "122"
  #|      },
  #|      "toggleName": "Feature.B4",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.B4 should be disabled for sessionId=155",
  #|      "context": {
  #|        "sessionId": "155"
  #|      },
  #|      "toggleName": "Feature.B4",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Feature.C4 should be disabled",
  #|      "context": {
  #|        "sessionId": "122"
  #|      },
  #|      "toggleName": "Feature.C4",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Feature.D4 should be enabled for all because of default strategy",
  #|      "context": {},
  #|      "toggleName": "Feature.D4",
  #|      "expectedResult": true
  #|    }
  #|  ]
  #|}

///|
let fixture_05 : String =
  #|{
  #|  "name": "05-gradual-rollout-random-strategy",
  #|  "state": {
  #|    "version": 1,
  #|    "features": [
  #|      {
  #|        "name": "Feature.A5",
  #|        "description": "Enabled toggle for 100%",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutRandom",
  #|            "parameters": {
  #|              "percentage": "100"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.B5",
  #|        "description": "Disabled toggle with 0% rollout",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutRandom",
  #|            "parameters": {
  #|              "percentage": "0"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.C5",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutRandom",
  #|            "parameters": {
  #|              "percentage": "0"
  #|            }
  #|          },
  #|          {
  #|            "name": "default"
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.D5",
  #|        "description": "Disabled toggle should be disabled",
  #|        "enabled": false,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutRandom",
  #|            "parameters": {
  #|              "percentage": "100"
  #|            }
  #|          }
  #|        ]
  #|      }
  #|    ]
  #|  },
  #|  "tests": [
  #|    {
  #|      "description": "Feature.A5 should be enabled",
  #|      "context": {},
  #|      "toggleName": "Feature.A5",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.B5 should be disabled",
  #|      "context": {},
  #|      "toggleName": "Feature.B5",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Feature.C5 should be enabled because of default strategy",
  #|      "context": {},
  #|      "toggleName": "Feature.C5",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.D5 should be disabled",
  #|      "context": {},
  #|      "toggleName": "Feature.D5",
  #|      "expectedResult": false
  #|    }
  #|  ]
  #|}

///|
let fixture_06 : String =
  #|{
  #|  "name": "06-remote-address-strategy",
  #|  "state": {
  #|    "version": 1,
  #|    "features": [
  #|      {
  #|        "name": "Feature.remoteAddress.A",
  #|        "description": "Enabled toggle for localhost",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "remoteAddress",
  #|            "parameters": {
  #|              "IPs": "127.0.0.1"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.remoteAddress.B",
  #|        "description": "Enabled toggle for list of IPs",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "remoteAddress",
  #|            "parameters": {
  #|              "IPs": "192.168.0.1, 192.168.0.2, 192.168.0.3"
  #|            }
  #|          }
  #|        ]
  #|      }
  #|      ,
  #|      {
  #|        "name": "Feature.remoteAddress.C",
  #|        "description": "Ignore invalid IP's in list",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "remoteAddress",
  #|            "parameters": {
  #|              "IPs": "192.168.0.1, 192.invalid, 192.168.0.2, 192.168.0.3"
  #|            }
  #|          }
  #|        ]
  #|      }
  #|    ]
  #|  },
  #|  "tests": [
  #|    {
  #|      "description": "Feature.remoteAddress.A should be enabled for localhost",
  #|      "context": {
  #|        "remoteAddress": "127.0.0.1"
  #|      },
  #|      "toggleName": "Feature.remoteAddress.A",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.remoteAddress.A should not be enabled for missing remoteAddress on context",
  #|      "context": {},
  #|      "toggleName": "Feature.remoteAddress.A",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Feature.remoteAddress.B should be enabled for remoteAddress 192.168.0.1",
  #|      "context": {
  #|        "remoteAddress": "192.168.0.1"
  #|      },
  #|      "toggleName": "Feature.remoteAddress.B",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.remoteAddress.B should not be enabled for remoteAddress 192.168.0.3",
  #|      "context": {
  #|        "remoteAddress": "192.168.0.3"
  #|      },
  #|      "toggleName": "Feature.remoteAddress.B",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.remoteAddress.B should not be enabled for remoteAddress 217.100.10.11",
  #|      "context": {
  #|        "remoteAddress": "217.100.10.11"
  #|      },
  #|      "toggleName": "Feature.remoteAddress.B",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Feature.remoteAddress.C should be enabled for remoteAddress 192.168.0.3",
  #|      "context": {
  #|        "remoteAddress": "192.168.0.3"
  #|      },
  #|      "toggleName": "Feature.remoteAddress.C",
  #|      "expectedResult": true
  #|    }
  #|  ]
  #|}

///|
let fixture_07 : String =
  #|{
  #|  "name": "07-multiple-strategies",
  #|  "state": {
  #|    "version": 1,
  #|    "features": [
  #|      {
  #|        "name": "Feature.multiStrategies.A",
  #|        "description": "Enabled for via last stratgy",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutRandom",
  #|            "parameters": {
  #|              "percentage": "0"
  #|            }
  #|          },
  #|          {
  #|            "name": "default",
  #|            "parameters": {}
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.multiStrategies.B",
  #|        "description": "Enabled for user=123",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutRandom",
  #|            "parameters": {
  #|              "percentage": "0"
  #|            }
  #|          },
  #|          {
  #|            "name": "userWithId",
  #|            "parameters": {
  #|              "userIds": "123"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.multiStrategies.C",
  #|        "description": "Enabled for user=123",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "gradualRolloutRandom",
  #|            "parameters": {
  #|              "percentage": "0"
  #|            }
  #|          },
  #|          {
  #|            "name": "userWithId",
  #|            "parameters": {
  #|              "userIds": "123"
  #|            }
  #|          },
  #|          {
  #|            "name": "gradualRolloutRandom",
  #|            "parameters": {
  #|              "percentage": "0"
  #|            }
  #|          }
  #|        ]
  #|      }
  #|    ]
  #|  },
  #|  "tests": [
  #|    {
  #|      "description": "Feature.multiStrategies.A should be enabled",
  #|      "context": {},
  #|      "toggleName": "Feature.multiStrategies.A",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.multiStrategies.B disabled for unknonw user",
  #|      "context": {},
  #|      "toggleName": "Feature.multiStrategies.B",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Feature.multiStrategies.B enabled for user=123",
  #|      "context": {
  #|        "userId": "123"
  #|      },
  #|      "toggleName": "Feature.multiStrategies.B",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.multiStrategies.C disabled for unknown users",
  #|      "context": {},
  #|      "toggleName": "Feature.multiStrategies.C",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Feature.multiStrategies.C disabled for user=22",
  #|      "context": {
  #|        "userId": "22"
  #|      },
  #|      "toggleName": "Feature.multiStrategies.C",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Feature.multiStrategies.C enabled for user=123",
  #|      "context": {
  #|        "userId": "123"
  #|      },
  #|      "toggleName": "Feature.multiStrategies.C",
  #|      "expectedResult": true
  #|    }
  #|  ]
  #|}

///|
let fixture_08 : String =
  #|{
  #|    "name": "08-variants",
  #|    "state": {
  #|        "version": 1,
  #|        "features": [
  #|            {
  #|                "name": "Feature.Variants.A",
  #|                "description": "Enabled",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {}
  #|                    }
  #|                ],
  #|                "variants": [
  #|                    {
  #|                        "name": "variant1",
  #|                        "weight": 1,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val1"
  #|                        }
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.Variants.B",
  #|                "description": "Enabled for user=123",
  #|                "enabled": true,
  #|                "strategies": [],
  #|                "variants": [
  #|                    {
  #|                        "name": "variant1",
  #|                        "weight": 1,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val1"
  #|                        }
  #|                    },
  #|                    {
  #|                        "name": "variant2",
  #|                        "weight": 1,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val2"
  #|                        }
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.Variants.C",
  #|                "description": "Testing three variants",
  #|                "enabled": true,
  #|                "strategies": [],
  #|                "variants": [
  #|                    {
  #|                        "name": "variant1",
  #|                        "weight": 33,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val1"
  #|                        }
  #|                    },
  #|                    {
  #|                        "name": "variant2",
  #|                        "weight": 33,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val2"
  #|                        }
  #|                    },
  #|                    {
  #|                        "name": "variant3",
  #|                        "weight": 33,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val3"
  #|                        }
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.Variants.D",
  #|                "description": "Variants with payload",
  #|                "enabled": true,
  #|                "strategies": [],
  #|                "variants": [
  #|                    {
  #|                        "name": "variant1",
  #|                        "weight": 1,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val1"
  #|                        }
  #|                    },
  #|                    {
  #|                        "name": "variant2",
  #|                        "weight": 49,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val2"
  #|                        }
  #|                    },
  #|                    {
  #|                        "name": "variant3",
  #|                        "weight": 50,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val3"
  #|                        }
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.Variants.override.D",
  #|                "description": "Variant with overrides",
  #|                "enabled": true,
  #|                "strategies": [],
  #|                "variants": [
  #|                    {
  #|                        "name": "variant1",
  #|                        "weight": 33,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val1"
  #|                        },
  #|                        "overrides": [{
  #|                            "contextName": "userId",
  #|                            "values": ["132", "61"]
  #|                        }]
  #|                    },
  #|                    {
  #|                        "name": "variant2",
  #|                        "weight": 33,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val2"
  #|                        }
  #|                    },
  #|                    {
  #|                        "name": "variant3",
  #|                        "weight": 34,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val3"
  #|                        }
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.Variants.E",
  #|                "description": "Enabled",
  #|                "enabled": false,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {}
  #|                    }
  #|                ],
  #|                "variants": [
  #|                    {
  #|                        "name": "variant1",
  #|                        "weight": 1,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val1"
  #|                        }
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.Variants.F",
  #|                "description": "Empty variants",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {}
  #|                    }
  #|                ],
  #|                "variants": []
  #|            },
  #|            {
  #|                "name": "Feature.Variants.G",
  #|                "description": "0% gradual rollout, but has variants",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "flexibleRollout",
  #|                        "parameters": {
  #|                            "rollout": "0",
  #|                            "stickiness": "default",
  #|                            "groupId": "feature-variant-g"
  #|                        }
  #|                    }
  #|                ],
  #|                "variants": [
  #|                    {
  #|                        "name": "variant1",
  #|                        "weight": 1,
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val1"
  #|                        }
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.Variants.H",
  #|                "description": "variant with numeric payload",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {}
  #|                    }
  #|                ],
  #|                "variants": [
  #|                    {
  #|                        "name": "variant1",
  #|                        "weight": 1,
  #|                        "payload": {
  #|                            "type": "number",
  #|                            "value": "1.2"
  #|                        }
  #|                    }
  #|                ]
  #|            }
  #|        ]
  #|    },
  #|    "variantTests": [
  #|        {
  #|            "description": "Feature.Variants.A should be enabled",
  #|            "context": {
  #|                "userId": "0"
  #|            },
  #|            "toggleName": "Feature.Variants.A",
  #|            "expectedResult": {
  #|                "name": "variant1",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.MissingToggle should be disabled missing toggle",
  #|            "context": {},
  #|            "toggleName": "Feature.Variants.MissingToggle",
  #|            "expectedResult": {
  #|                "name": "disabled",
  #|                "enabled": false,
  #|                "feature_enabled": false
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.B should give variant2 for user 2",
  #|            "context": {
  #|                "userId": "2"
  #|            },
  #|            "toggleName": "Feature.Variants.B",
  #|            "expectedResult": {
  #|                "name": "variant2",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val2"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.B should give variant 1 for user 0",
  #|            "context": {
  #|                "userId": "0"
  #|            },
  #|            "toggleName": "Feature.Variants.B",
  #|            "expectedResult": {
  #|                "name": "variant1",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.C should return variant1",
  #|            "context": {
  #|                "userId": "232"
  #|            },
  #|            "toggleName": "Feature.Variants.C",
  #|            "expectedResult": {
  #|                "name": "variant1",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.C should return variant2",
  #|            "context": {
  #|                "userId": "607"
  #|            },
  #|            "toggleName": "Feature.Variants.C",
  #|            "expectedResult": {
  #|                "name": "variant2",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val2"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.C should return variant3",
  #|            "context": {
  #|                "userId": "656"
  #|            },
  #|            "toggleName": "Feature.Variants.C",
  #|            "expectedResult": {
  #|                "name": "variant3",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val3"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.D should return variant1",
  #|            "context": {
  #|                "userId": "712"
  #|            },
  #|            "toggleName": "Feature.Variants.D",
  #|            "expectedResult": {
  #|                "name": "variant1",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.D should return variant2",
  #|            "context": {
  #|                "userId": "525"
  #|            },
  #|            "toggleName": "Feature.Variants.D",
  #|            "expectedResult": {
  #|                "name": "variant2",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val2"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.D should return variant3",
  #|            "context": {
  #|                "userId": "537"
  #|            },
  #|            "toggleName": "Feature.Variants.D",
  #|            "expectedResult": {
  #|                "name": "variant3",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val3"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.override.D should return variant1 for user 132",
  #|            "context": {
  #|                "userId": "132"
  #|            },
  #|            "toggleName": "Feature.Variants.override.D",
  #|            "expectedResult": {
  #|                "name": "variant1",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.override.D should return variant1 for user 61",
  #|            "context": {
  #|                "userId": "61"
  #|            },
  #|            "toggleName": "Feature.Variants.override.D",
  #|            "expectedResult": {
  #|                "name": "variant1",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.override.D should return variant2 for user 388",
  #|            "context": {
  #|                "userId": "388"
  #|            },
  #|            "toggleName": "Feature.Variants.override.D",
  #|            "expectedResult": {
  #|                "name": "variant2",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val2"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.E should be disabled",
  #|            "context": {
  #|                "userId": "0"
  #|            },
  #|            "toggleName": "Feature.Variants.E",
  #|            "expectedResult": {
  #|                "name": "disabled",
  #|                "enabled": false,
  #|                "feature_enabled": false
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.F should be disabled when variants are empty",
  #|            "context": {
  #|                "userId": "0"
  #|            },
  #|            "toggleName": "Feature.Variants.F",
  #|            "expectedResult": {
  #|                "name": "disabled",
  #|                "enabled": false,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.G should be disabled when feature is calculated as false, but has variants",
  #|            "context": {
  #|                "userId": "0"
  #|            },
  #|            "toggleName": "Feature.Variants.G",
  #|            "expectedResult": {
  #|                "name": "disabled",
  #|                "enabled": false,
  #|                "feature_enabled": false
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.Variants.H should return variant1 with numeric type payload",
  #|            "context": {
  #|                "userId": "0"
  #|            },
  #|            "toggleName": "Feature.Variants.H",
  #|            "expectedResult": {
  #|                "name": "variant1",
  #|                "payload": {
  #|                    "type": "number",
  #|                    "value": "1.2"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        }
  #|    ]
  #|}

///|
let fixture_09 : String =
  #|{
  #|    "name": "09-strategy-constraints",
  #|    "state": {
  #|        "version": 1,
  #|        "features": [
  #|            {
  #|                "name": "Feature.constraints.simple",
  #|                "description": "Enabled only in dev",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "environment",
  #|                                "operator": "IN",
  #|                                "values": ["dev"]
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.constraints.list",
  #|                "description": "Enabled in dev, stage, prod",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "environment",
  #|                                "operator": "IN",
  #|                                "values": ["dev", "stage", "prod"]
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.constraints.multi",
  #|                "description": "Enabled in prod and only for users 1, 2, 3",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "environment",
  #|                                "operator": "IN",
  #|                                "values": ["prod"]
  #|
  #|                            },
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "IN",
  #|                                "values": ["1", "2", "3"]
  #|
  #|                            },
  #|                            {
  #|                                "contextName": "appName",
  #|                                "operator": "NOT_IN",
  #|                                "values": ["web", "sun-app"]
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.constraints.userWithId",
  #|                "description": "Enabled in prod for userWithId=123",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "userWithId",
  #|                        "parameters": {
  #|                            "userIds": "123"
  #|                        },
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "environment",
  #|                                "operator": "IN",
  #|                                "values": ["prod"]
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.constraints.custom",
  #|                "description": "Enabled in prod in country IN (norway or sweeden)",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "environment",
  #|                                "operator": "IN",
  #|                                "values": ["prod"]
  #|
  #|                            },
  #|                            {
  #|                                "contextName": "country",
  #|                                "operator": "IN",
  #|                                "values": ["norway", "sweeden"]
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.constraints.dual",
  #|                "description": "Enabled in prod and not in qa and dev",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "environment",
  #|                                "operator": "IN",
  #|                                "values": ["prod", "dev"]
  #|
  #|                            },
  #|                            {
  #|                                "contextName": "environment",
  #|                                "operator": "NOT_IN",
  #|                                "values": ["dev", "qa"]
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.constraints.empty",
  #|                "description": "Always disabled for empty list of values",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "environment",
  #|                                "operator": "IN",
  #|                                "values": []
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.constraints.empty-not-in",
  #|                "description": "Always enabled for value not in empty list",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "environment",
  #|                                "operator": "NOT_IN",
  #|                                "values": []
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.constraints.multiple.strategies",
  #|                "description": "Feature constraints has multiple strategies",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "IN",
  #|                                "values": ["123"]
  #|
  #|                            }
  #|                        ]
  #|                    },
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "IN",
  #|                                "values": ["456"]
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            }
  #|        ]
  #|    },
  #|    "tests": [
  #|        {
  #|          "description": "Feature.constraints.simple should not be enabled in default environment",
  #|          "context": {
  #|              "environment": "default"
  #|          },
  #|          "toggleName": "Feature.constraints.simple",
  #|          "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.constraints.simple should be enabled in dev environment",
  #|            "context": {
  #|                "environment": "dev"
  #|            },
  #|            "toggleName": "Feature.constraints.simple",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.constraints.list should be enabled in stage environment",
  #|            "context": {
  #|                "environment": "stage"
  #|            },
  #|            "toggleName": "Feature.constraints.list",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.constraints.list should NOT be enabled in qa environment",
  #|            "context": {
  #|                "environment": "qa"
  #|            },
  #|            "toggleName": "Feature.constraints.list",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.constraints.multi should be enabled in prod for user 2",
  #|            "context": {
  #|                "environment": "prod",
  #|                "userId": "2"
  #|            },
  #|            "toggleName": "Feature.constraints.multi",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.constraints.multi should NOT be enabled for unknown user",
  #|            "context": {
  #|                "environment": "prod"
  #|            },
  #|            "toggleName": "Feature.constraints.multi",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.constraints.multi should NOT be enabled appName=web",
  #|            "context": {
  #|                "environment": "prod",
  #|                "userId": "2",
  #|                "appName": "web"
  #|            },
  #|            "toggleName": "Feature.constraints.multi",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.constraints.custom should be enabled in prod for norway",
  #|            "context": {
  #|                "environment": "prod",
  #|                "properties": {
  #|                    "country": "norway"
  #|                }
  #|            },
  #|            "toggleName": "Feature.constraints.custom",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.constraints.custom should NOT be enabled in prod for denmark",
  #|            "context": {
  #|                "environment": "prod",
  #|                "properties": {
  #|                    "country": "denmark"
  #|                }
  #|            },
  #|            "toggleName": "Feature.constraints.custom",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.constraints.dual should be enabled in prod",
  #|            "context": {
  #|                "environment": "prod"
  #|            },
  #|            "toggleName": "Feature.constraints.dual",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.constraints.dual should not be enabled in dev",
  #|            "context": {
  #|                "environment": "dev"
  #|            },
  #|            "toggleName": "Feature.constraints.dual",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.constraints.empty should always be disabled",
  #|            "context": {
  #|                "environment": "dev"
  #|            },
  #|            "toggleName": "Feature.constraints.empty",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Always enabled for value not in empty list",
  #|            "context": {
  #|                "environment": "dev"
  #|            },
  #|            "toggleName": "Feature.constraints.empty-not-in",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Enabled in prod for userId=123",
  #|            "context": {
  #|                "environment": "prod",
  #|                "userId": "123"
  #|            },
  #|            "toggleName": "Feature.constraints.userWithId",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Disabled in dev for userId=123",
  #|            "context": {
  #|                "environment": "dev",
  #|                "userId": "123"
  #|            },
  #|            "toggleName": "Feature.constraints.userWithId",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Disabled in prod for userId=44",
  #|            "context": {
  #|                "environment": "prod",
  #|                "userId": "44"
  #|            },
  #|            "toggleName": "Feature.constraints.userWithId",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Constraint should work with the latter strategy",
  #|            "context": {
  #|                "userId": "456"
  #|            },
  #|            "toggleName": "Feature.constraints.multiple.strategies",
  #|            "expectedResult": true
  #|        }
  #|    ]
  #|}

///|
let fixture_10 : String =
  #|{
  #|    "name": "10-flexible-rollout-strategy",
  #|    "state": {
  #|        "version": 1,
  #|        "features": [
  #|            {
  #|                "name": "Feature.flexibleRollout.100",
  #|                "description": "Should be enabled",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "flexibleRollout",
  #|                        "parameters": {
  #|                            "rollout": "100",
  #|                            "stickiness": "default",
  #|                            "groupId": "Feature.flexibleRollout.100"
  #|                        },
  #|                        "constraints": []
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.flexibleRollout.10",
  #|                "description": "Should be enabled",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "flexibleRollout",
  #|                        "parameters": {
  #|                            "rollout": "10",
  #|                            "stickiness": "default",
  #|                            "groupId": "Feature.flexibleRollout.10"
  #|                        },
  #|                        "constraints": []
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.flexibleRollout.0",
  #|                "description": "Should be disabled",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "flexibleRollout",
  #|                        "parameters": {
  #|                            "rollout": "0",
  #|                            "stickiness": "default",
  #|                            "groupId": "Feature.flexibleRollout.0"
  #|                        },
  #|                        "constraints": []
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.flexibleRollout.userId.55",
  #|                "description": "Should be enabled",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "flexibleRollout",
  #|                        "parameters": {
  #|                            "rollout": "55",
  #|                            "stickiness": "userId",
  #|                            "groupId": "Feature.flexibleRollout.userId.55"
  #|                        },
  #|                        "constraints": []
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.flexibleRollout.sessionId.42",
  #|                "description": "Should be enabled",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "flexibleRollout",
  #|                        "parameters": {
  #|                            "rollout": "42",
  #|                            "stickiness": "sessionId",
  #|                            "groupId": "Feature.flexibleRollout.sessionId.42"
  #|                        },
  #|                        "constraints": []
  #|                    }
  #|                ]
  #|            }
  #|        ]
  #|    },
  #|    "tests": [
  #|        {
  #|          "description": "Feature.flexibleRollout.100 should always be enabled",
  #|          "context": {},
  #|          "toggleName": "Feature.flexibleRollout.100",
  #|          "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.flexibleRollout.10 should be enabled for userId=174",
  #|            "context": {
  #|                "userId": "174"
  #|            },
  #|            "toggleName": "Feature.flexibleRollout.10",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.flexibleRollout.10 should be disabled for userId=499",
  #|            "context": {
  #|                "userId": "499"
  #|            },
  #|            "toggleName": "Feature.flexibleRollout.10",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.flexibleRollout.10 should be enabled for sessionId=174",
  #|            "context": {
  #|                "sessionId": "174"
  #|            },
  #|            "toggleName": "Feature.flexibleRollout.10",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.flexibleRollout.10 should be disabled for sessionId=499",
  #|            "context": {
  #|                "sessionId": "499"
  #|            },
  #|            "toggleName": "Feature.flexibleRollout.10",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.flexibleRollout.userId.55 should be enabled for userId=25",
  #|            "context": {
  #|                "userId": "25"
  #|            },
  #|            "toggleName": "Feature.flexibleRollout.userId.55",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.flexibleRollout.userId.55 should be disabled for sessionId=25",
  #|            "context": {
  #|                "sessionId": "25"
  #|            },
  #|            "toggleName": "Feature.flexibleRollout.userId.55",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.flexibleRollout.userId.55 should be disabled if no userId in context",
  #|            "context": {},
  #|            "toggleName": "Feature.flexibleRollout.userId.55",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.flexibleRollout.sessionId.42 should be enabled for sessionId=147",
  #|            "context": {
  #|                "sessionId": "147"
  #|            },
  #|            "toggleName": "Feature.flexibleRollout.sessionId.42",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.flexibleRollout.0 should be disbaled for rollout=0",
  #|            "context": {
  #|                "sessionId": "147",
  #|                "userId": "12"
  #|            },
  #|            "toggleName": "Feature.flexibleRollout.0",
  #|            "expectedResult": false
  #|        }
  #|    ]
  #|}

///|
let fixture_11 : String =
  #|{
  #|    "name": "11-strategy-constraints-edge-cases",
  #|    "state": {
  #|        "version": 1,
  #|        "features": [
  #|            {
  #|                "name": "Feature.constraints.no_values",
  #|                "description": "Not enabled with constraints and no values",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "environment",
  #|                                "operator": "IN",
  #|                                "values": []
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.constraints.no_values_NOT_IN",
  #|                "description": "Is enabled with constraints and NOT_IN empty values",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "environment",
  #|                                "operator": "NOT_IN",
  #|                                "values": []
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.constraints.empty",
  #|                "description": "Is enabled with empty constraints array",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": []
  #|                    }
  #|                ]
  #|            }
  #|        ]
  #|    },
  #|    "tests": [
  #|        {
  #|          "description": "Feature.constraints.no_value should not be enabled in default environment",
  #|          "context": {
  #|              "environment": "default"
  #|          },
  #|          "toggleName": "Feature.constraints.no_values",
  #|          "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.constraints.no_value should not be enabled in empty environment",
  #|            "context": {},
  #|            "toggleName": "Feature.constraints.no_values",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.constraints.no_values_NOT_IN should be enabled in default environment",
  #|            "context": {
  #|                "environment": "default"
  #|            },
  #|            "toggleName": "Feature.constraints.no_values_NOT_IN",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.constraints.no_values_NOT_IN should be enabled in empty environment",
  #|            "context": {},
  #|            "toggleName": "Feature.constraints.no_values_NOT_IN",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.constraints.empty should be enabled",
  #|            "context": {
  #|                "environment": "default"
  #|            },
  #|            "toggleName": "Feature.constraints.empty",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.constraints.empty should be enabled for empty env",
  #|            "context": {},
  #|            "toggleName": "Feature.constraints.empty",
  #|            "expectedResult": true
  #|        }
  #|    ]
  #|}

///|
let fixture_12 : String =
  #|{
  #|    "name": "12-custom-stickiness",
  #|    "state": {
  #|        "version": 1,
  #|        "features": [
  #|            {
  #|                "name": "Feature.flexible.rollout.custom.stickiness_100",
  #|                "description": "Should support custom stickiness as option",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "flexibleRollout",
  #|                        "parameters": {
  #|                            "rollout": "100",
  #|                            "stickiness": "customField",
  #|                            "groupId": "Feature.flexible.rollout.custom.stickiness_100"
  #|                        },
  #|                        "constraints": []
  #|                    }
  #|                ],
  #|                "variants": [
  #|                    {
  #|                        "name": "blue",
  #|                        "weight": 25,
  #|                        "stickiness": "customField",
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val1"
  #|                        }
  #|                    },
  #|                    {
  #|                        "name": "red",
  #|                        "weight": 25,
  #|                        "stickiness": "customField",
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val1"
  #|                        }
  #|                    },
  #|                    {
  #|                        "name": "green",
  #|                        "weight": 25,
  #|                        "stickiness": "customField",
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val1"
  #|                        }
  #|                    },
  #|                    {
  #|                        "name": "yellow",
  #|                        "weight": 25,
  #|                        "stickiness": "customField",
  #|                        "payload": {
  #|                            "type": "string",
  #|                            "value": "val1"
  #|                        }
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Feature.flexible.rollout.custom.stickiness_50",
  #|                "description": "Should support custom stickiness as option",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "flexibleRollout",
  #|                        "parameters": {
  #|                            "rollout": "50",
  #|                            "stickiness": "customField",
  #|                            "groupId": "Feature.flexible.rollout.custom.stickiness_50"
  #|                        },
  #|                        "constraints": []
  #|                    }
  #|                ]
  #|            }
  #|        ]
  #|    },
  #|    "tests": [
  #|        {
  #|          "description": "Feature.flexible.rollout.custom.stickiness_100 should be enabled without field defined for 100%",
  #|          "context": { "properties": {"customField": "any_value"}},
  #|          "toggleName": "Feature.flexible.rollout.custom.stickiness_100",
  #|          "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.flexible.rollout.custom.stickiness_50 should not be enabled without custom field",
  #|            "context": {},
  #|            "toggleName": "Feature.flexible.rollout.custom.stickiness_50",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.flexible.rollout.custom.stickiness_50 should not enabled for customField=402",
  #|            "context": {
  #|                "properties": {"customField": "402"}
  #|            },
  #|            "toggleName": "Feature.flexible.rollout.custom.stickiness_50",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Feature.flexible.rollout.custom.stickiness_50 should be enabled for customField=388",
  #|            "context": {
  #|                "properties": {"customField": "388"}
  #|            },
  #|            "toggleName": "Feature.flexible.rollout.custom.stickiness_50",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Feature.flexible.rollout.custom.stickiness_50 should be enabled for customField=39",
  #|            "context": {
  #|                "properties": {"customField": "39"}
  #|            },
  #|            "toggleName": "Feature.flexible.rollout.custom.stickiness_50",
  #|            "expectedResult": true
  #|        }
  #|    ],
  #|    "variantTests": [
  #|        {
  #|            "description": "Feature.flexible.rollout.custom.stickiness_100 and customField=616 yields blue",
  #|            "context": {
  #|                "properties": {"customField": "616"}
  #|            },
  #|            "toggleName": "Feature.flexible.rollout.custom.stickiness_100",
  #|            "expectedResult": {
  #|                "name": "blue",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.flexible.rollout.custom.stickiness_100 and customField=503 yields red",
  #|            "context": {
  #|                "properties": {"customField": "503"}
  #|            },
  #|            "toggleName": "Feature.flexible.rollout.custom.stickiness_100",
  #|            "expectedResult": {
  #|                "name": "red",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.flexible.rollout.custom.stickiness_100 and customField=438 yields green",
  #|            "context": {
  #|                "properties": {"customField": "438"}
  #|            },
  #|            "toggleName": "Feature.flexible.rollout.custom.stickiness_100",
  #|            "expectedResult": {
  #|                "name": "green",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        },
  #|        {
  #|            "description": "Feature.flexible.rollout.custom.stickiness_100 and customField=44 yields yellow",
  #|            "context": {
  #|                "properties": {"customField": "44"}
  #|            },
  #|            "toggleName": "Feature.flexible.rollout.custom.stickiness_100",
  #|            "expectedResult": {
  #|                "name": "yellow",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                },
  #|                "enabled": true,
  #|                "feature_enabled": true
  #|            }
  #|        }
  #|    ]
  #|}

///|
let fixture_13 : String =
  #|{
  #|    "name": "13-constraint-operators",
  #|    "state": {
  #|        "version": 1,
  #|        "features": [
  #|            {
  #|                "name": "F1.startsWith",
  #|                "description": "startsWith",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "customField",
  #|                                "operator": "STR_STARTS_WITH",
  #|                                "values": ["some-string"]
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F2.startsWith.multiple",
  #|                "description": "starts with",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "customField",
  #|                                "operator": "STR_STARTS_WITH",
  #|                                "values": ["e1", "e2"]
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F2.startsWith.caseInsensitve",
  #|                "description": "starts with case insensitive",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "customField",
  #|                                "operator": "STR_STARTS_WITH",
  #|                                "values": ["TEST"],
  #|                                "caseInsensitive": true
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F3.endsWith",
  #|                "description": "endsWith",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "email",
  #|                                "operator": "STR_ENDS_WITH",
  #|                                "values": ["some-email.com"]
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F3.endsWith.ignoringCase",
  #|                "description": "endsWith",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "email",
  #|                                "operator": "STR_ENDS_WITH",
  #|                                "values": ["some-email.com"],
  #|                                "caseInsensitive": true
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F4.contains",
  #|                "description": "contains",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "email",
  #|                                "operator": "STR_CONTAINS",
  #|                                "values": ["email"]
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F4.contains.inverted",
  #|                "description": "contains",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "email",
  #|                                "operator": "STR_CONTAINS",
  #|                                "values": ["email"],
  #|                                "inverted": true
  #|
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F5.numEq",
  #|                "description": "contains",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "someValue",
  #|                                "operator": "NUM_EQ",
  #|                                "value": "12"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F5.numEq.float",
  #|                "description": "contains",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "someValue",
  #|                                "operator": "NUM_EQ",
  #|                                "value": "12.0"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F5.numEq.inverted",
  #|                "description": "contains",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "someValue",
  #|                                "operator": "NUM_EQ",
  #|                                "value": "12",
  #|                                "inverted": true
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F5.numGT",
  #|                "description": "contains",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "someValue",
  #|                                "operator": "NUM_GT",
  #|                                "value": "12"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F5.numGTE",
  #|                "description": "contains",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "someValue",
  #|                                "operator": "NUM_GTE",
  #|                                "value": "12"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F5.numLT",
  #|                "description": "contains",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "someValue",
  #|                                "operator": "NUM_LT",
  #|                                "value": "12"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F5.numLTE",
  #|                "description": "contains",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "someValue",
  #|                                "operator": "NUM_LTE",
  #|                                "value": "12"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F6.number-range",
  #|                "description": "range of numbers",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "someValue",
  #|                                "operator": "NUM_GT",
  #|                                "value": "12"
  #|                            },
  #|                            {
  #|                                "contextName": "someValue",
  #|                                "operator": "NUM_LT",
  #|                                "value": "16"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F7.dateAfter",
  #|                "description": "dates",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "currentTime",
  #|                                "operator": "DATE_AFTER",
  #|                                "value": "2022-01-29T13:00:00.000Z"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F7.dateBefore",
  #|                "description": "dates",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "currentTime",
  #|                                "operator": "DATE_BEFORE",
  #|                                "value": "2022-01-29T13:00:00.000Z"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F7.date-range",
  #|                "description": "dates",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "currentTime",
  #|                                "operator": "DATE_AFTER",
  #|                                "value": "2022-01-22T13:00:00.000Z"
  #|                            },
  #|                            {
  #|                                "contextName": "currentTime",
  #|                                "operator": "DATE_BEFORE",
  #|                                "value": "2022-01-29T13:00:00.000Z"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F7.date-with-timezone",
  #|                "description": "dates",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "currentTime",
  #|                                "operator": "DATE_AFTER",
  #|                                "value": "2022-01-22T13:00:00.000+02:00"
  #|                            },
  #|                            {
  #|                                "contextName": "currentTime",
  #|                                "operator": "DATE_BEFORE",
  #|                                "value": "2022-01-22T14:00:00.000+02:00"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F7.invalid-operator",
  #|                "description": "invalid",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "customField",
  #|                                "operator": "NOT_A_VALID_OPERATOR",
  #|                                "value": "2022-01-22T13:00:00.000Z"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.missing-field.IN",
  #|                "description": "missing field",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "customFieldMissing",
  #|                                "operator": "IN",
  #|                                "values": ["s1"]
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.missing-field.NOT_IN",
  #|                "description": "missing field",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "customFieldMissing",
  #|                                "operator": "NOT_IN",
  #|                                "values": ["s1"]
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F9.inverted.IN",
  #|                "description": "inverted IN",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "someValue",
  #|                                "operator": "IN",
  #|                                "values": ["s1","s2"],
  #|                                "inverted": true
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F10.inverted.NOT_IN",
  #|                "description": "inverted NOT_IN",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "someValue",
  #|                                "operator": "NOT_IN",
  #|                                "values": ["s1","s2"],
  #|                                "inverted": true
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            }
  #|        ]
  #|    },
  #|    "tests": [
  #|        {
  #|          "description": "F1.startsWith should be enabled",
  #|          "context": {
  #|              "properties": {
  #|                  "customField": "some-string-is-cool"
  #|              }
  #|          },
  #|          "toggleName": "F1.startsWith",
  #|          "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F1.startsWith should be disabled",
  #|            "context": {
  #|                "properties": {
  #|                    "customField": "some2-is-cool-string"
  #|                }
  #|            },
  #|            "toggleName": "F1.startsWith",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F2.startsWith.multiple should be enabled",
  #|            "context": {
  #|                "properties": {
  #|                    "customField": "e2 cool"
  #|                }
  #|            },
  #|            "toggleName": "F2.startsWith.multiple",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F2.startsWith.multiple should be disabled",
  #|            "context": {
  #|                "properties": {
  #|                    "customField": "cool e1"
  #|                }
  #|            },
  #|            "toggleName": "F2.startsWith.multiple",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F2.startsWith.caseInsensitve should be enabled",
  #|            "context": {
  #|                "properties": {
  #|                    "customField": "test@example.com"
  #|                }
  #|            },
  #|            "toggleName": "F2.startsWith.caseInsensitve",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F2.startsWith.caseInsensitve should handle various cases when enabled",
  #|            "context": {
  #|                "properties": {
  #|                    "customField": "TEsT@example.com"
  #|                }
  #|            },
  #|            "toggleName": "F2.startsWith.caseInsensitve",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F3.endsWith should be enabled",
  #|            "context": {
  #|                "properties": {
  #|                    "email": "test@some-email.com"
  #|                }
  #|            },
  #|            "toggleName": "F3.endsWith",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F3.endsWith should be disabled when casing is incorrect",
  #|            "context": {
  #|                "properties": {
  #|                    "email": "test@some-EMAIL.com"
  #|                }
  #|            },
  #|            "toggleName": "F3.endsWith",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F3.endsWith.ignoringCase should be enabled",
  #|            "context": {
  #|                "properties": {
  #|                    "email": "test@SOME-EMAIL.com"
  #|                }
  #|            },
  #|            "toggleName": "F3.endsWith.ignoringCase",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F3.endsWith should be disabled",
  #|            "context": {
  #|                "properties": {
  #|                    "email": "test@another-email.com"
  #|                }
  #|            },
  #|            "toggleName": "F3.endsWith",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F4.contains should be enabled",
  #|            "context": {
  #|                "properties": {
  #|                    "email": "test@some-email.com"
  #|                }
  #|            },
  #|            "toggleName": "F4.contains",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F4.contains should be disabled",
  #|            "context": {
  #|                "properties": {
  #|                    "email": "test@another.com"
  #|                }
  #|            },
  #|            "toggleName": "F4.contains",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F4.contains.inverted should be enabled",
  #|            "context": {
  #|                "properties": {
  #|                    "email": "test@another.com"
  #|                }
  #|            },
  #|            "toggleName": "F4.contains.inverted",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F5.numEq",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "12"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numEq",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F5.numEq works for floats",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "12.0"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numEq",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F5.numEq.inverted should be false",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "12"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numEq.inverted",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F5.numEq.float works for floats",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "12.0"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numEq.float",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F5.numEq.float works for integers",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "12"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numEq.float",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F5.numEq.inverted should be true",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "13"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numEq.inverted",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F5.numGT should be true",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "13"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numGT",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F5.numGT should be false",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "12"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numGT",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F5.numGTE should be true when equal",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "12"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numGTE",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F5.numGTE should be true when larger",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "13"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numGTE",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F5.numGTE should be false when lower",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "11"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numGTE",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F5.numLTE should be false when higher",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "13"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numLTE",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F5.numLTE should be true when equal",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "12"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numLTE",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F5.numLTE should be true when lower",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "0"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numLTE",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F5.numLT should be true when lower",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "0"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numLT",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F5.numLT should be false when equal",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "12"
  #|                }
  #|            },
  #|            "toggleName":  "F5.numLT",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F6.number-range should be false when not in range",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "11"
  #|                }
  #|            },
  #|            "toggleName":  "F6.number-range",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F6.number-range should be true when in range",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "14"
  #|                }
  #|            },
  #|            "toggleName":  "F6.number-range",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F7.dateAfter should be enabled",
  #|            "context": {
  #|                "currentTime": "2022-01-30T13:00:00.000Z"
  #|            },
  #|            "toggleName":  "F7.dateAfter",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F7.dateAfter should be disabled",
  #|            "context": {
  #|                "currentTime": "2022-01-28T13:00:00.000Z"
  #|            },
  #|            "toggleName":  "F7.dateAfter",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F7.dateAfter is exclusive of date parameter",
  #|            "context": {
  #|                "currentTime": "2022-01-29T13:00:00.000Z"
  #|            },
  #|            "toggleName":  "F7.dateAfter",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F7.dateBefore should be enabled",
  #|            "context": {
  #|                "currentTime": "2022-01-28T13:00:00.000Z"
  #|            },
  #|            "toggleName":  "F7.dateBefore",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F7.dateBefore should be disabled",
  #|            "context": {
  #|                "currentTime": "2022-01-30T13:00:00.000Z"
  #|            },
  #|            "toggleName":  "F7.dateBefore",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F7.dateBefore is exclusive of date parameter",
  #|            "context": {
  #|                "currentTime": "2022-01-29T13:00:00.000Z"
  #|            },
  #|            "toggleName":  "F7.dateBefore",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F7.date-range should be enabled",
  #|            "context": {
  #|                "currentTime": "2022-01-25T13:00:00.000Z"
  #|            },
  #|            "toggleName":  "F7.date-range",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F7.date-with-timezone should respect timezone",
  #|            "context": {
  #|                "currentTime": "2022-01-22T11:30:00.000Z"
  #|            },
  #|            "toggleName": "F7.date-with-timezone",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F7.invalid-operator should always return false",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "12"
  #|                }
  #|            },
  #|            "toggleName":  "F7.invalid-operator",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.missing-field.IN should return false",
  #|            "context": {},
  #|            "toggleName":  "F8.missing-field.IN",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.missing-field.IN should return true when present",
  #|            "context": {
  #|                "properties": {
  #|                    "customFieldMissing": "s1"
  #|                }
  #|            },
  #|            "toggleName":  "F8.missing-field.IN",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.missing-field.NOT_IN should return true",
  #|            "context": {},
  #|            "toggleName":  "F8.missing-field.NOT_IN",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.missing-field.NOT_IN should return true when null",
  #|            "context": {
  #|                "properties": {
  #|                    "customFieldMissing": null
  #|                }
  #|            },
  #|            "toggleName":  "F8.missing-field.NOT_IN",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F9.inverted.IN should return false when present but inverted",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "s1"
  #|                }
  #|            },
  #|            "toggleName":  "F9.inverted.IN",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F10.inverted.NOT_IN should return true when present but inverted",
  #|            "context": {
  #|                "properties": {
  #|                    "someValue": "s1"
  #|                }
  #|            },
  #|            "toggleName":  "F10.inverted.NOT_IN",
  #|            "expectedResult": true
  #|        }
  #|    ]
  #|}

///|
let fixture_14 : String =
  #|{
  #|    "name": "14-constraint-semver-operators",
  #|    "state": {
  #|        "version": 2,
  #|        "features": [
  #|            {
  #|                "name": "F8.semverEQ",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_EQ",
  #|                                "value": "1.2.2"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.semverGT",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_GT",
  #|                                "value": "1.2.2"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.semverGTE",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_GTE",
  #|                                "value": "1.2.2"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.semverLT",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_LT",
  #|                                "value": "1.2.2"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.semverLTE",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_LTE",
  #|                                "value": "1.2.2"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.semverAlphaGT",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_GT",
  #|                                "value": "2.0.0-alpha.1"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.semverAlphaLT",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_LT",
  #|                                "value": "2.0.0-alpha.1"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.semverAlphaVersioning",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_LT",
  #|                                "value": "2.0.0-alpha.3"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.alphaUnnumbered",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_GT",
  #|                                "value": "2.0.0-alpha"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.releaseCandidate",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_GT",
  #|                                "value": "2.0.0-rc"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.invalidSemverWithLeadingV",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_EQ",
  #|                                "value": "v2.0.0"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.semverMetadataEQ",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_EQ",
  #|                                "value": "1.2.2+metadata"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.semverPreReleaseMetadataEQ",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_EQ",
  #|                                "value": "1.2.2-alpha.1+metadata"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.semverPreReleaseMetadataLT",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_LT",
  #|                                "value": "1.2.2-alpha.1+metadata"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "F8.semverPreReleaseMetadataGT",
  #|                "description": "semver",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "version",
  #|                                "operator": "SEMVER_GT",
  #|                                "value": "1.2.2-alpha.1+metadata.1"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            }
  #|        ]
  #|    },
  #|    "tests": [
  #|        {
  #|            "description": "F8.semverEQ should be enabled",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverEQ",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverEQ should be enabled for metadata",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2+metadata"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverEQ",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverEQ should be disabled",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.0"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverEQ",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.semverGT should be enabled",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.3"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverGT",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverGT should be disabled",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.0"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverGT",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.semverGT should be disabled if only metadata differs",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2+metadata"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverGT",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.semverGTE should be enabled",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverGTE",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverGTE should be enabled for greater",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.3"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverGTE",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverGTE should be disabled",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.1"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverGTE",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.semverLT should be enabled",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.1"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverLT",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverLT should be disabled",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.3"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverLT",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.semverLT should be disabled if only metadata differs",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2+metadata"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverLT",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.semverLTE should be enabled",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverLTE",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverLTE should be enabled for less",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.1"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverLTE",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverLTE should be disabled",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.3"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverLTE",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.semverAlphaGT is less than beta",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "2.0.0-beta.1"
  #|                }
  #|            },
  #|            "toggleName": "F8.semverAlphaGT",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverAlphaGT operator is less than release",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "2.0.0"
  #|                }
  #|            },
  #|            "toggleName": "F8.semverAlphaGT",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverAlphaLT is less than beta",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "2.0.0-beta.1"
  #|                }
  #|            },
  #|            "toggleName": "F8.semverAlphaLT",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.semverAlphaLT is greater than old beta",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.9.1-beta.1"
  #|                }
  #|            },
  #|            "toggleName": "F8.semverAlphaLT",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverAlphaLT is less than release",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "2.0.0"
  #|                }
  #|            },
  #|            "toggleName": "F8.semverAlphaLT",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.semverAlphaVersioning alpha.1 is less than alpha.3",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "2.0.0-alpha.1"
  #|                }
  #|            },
  #|            "toggleName": "F8.semverAlphaVersioning",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverAlphaVersioning alpha.4 is greater than alpha.3",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "2.0.0-alpha.4"
  #|                }
  #|            },
  #|            "toggleName": "F8.semverAlphaVersioning",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.alphaUnnumbered - unnumbered is LT than numbered",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "2.0.0-alpha.1"
  #|                }
  #|            },
  #|            "toggleName": "F8.alphaUnnumbered",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.releaseCandidate - alpha is not greater than rc",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "2.0.0-alpha.1"
  #|                }
  #|            },
  #|            "toggleName": "F8.releaseCandidate",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.releaseCandidate - beta is not greater tha rc",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "2.0.0-beta.1"
  #|                }
  #|            },
  #|            "toggleName": "F8.releaseCandidate",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.releaseCandidate - release is greater than rc",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "2.0.0"
  #|                }
  #|            },
  #|            "toggleName": "F8.releaseCandidate",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.invalidSemverWithLeadingV - invalid semver resolves to false",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "v2.0.0"
  #|                }
  #|            },
  #|            "toggleName": "F8.invalidSemverWithLeadingV",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.invalidSemverWithLeadingV - broken semver resolves to false",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "not a semver"
  #|                }
  #|            },
  #|            "toggleName": "F8.invalidSemverWithLeadingV",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.semverMetadataEQ should be enabled if only metadata differs",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverMetadataEQ",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverMetadataEQ should be enabled if only metadata differs and contains a dot",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2+metadata.1"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverMetadataEQ",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverMetadataEQ should be enabled if metadata matches",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2+metadata"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverMetadataEQ",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverPreReleaseMetadataEQ should be enabled if only metadata differs",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2-alpha.1"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverPreReleaseMetadataEQ",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverPreReleaseMetadataEQ should be enabled if only metadata differs and contains a dot",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2-alpha.1+metadata.1"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverPreReleaseMetadataEQ",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverPreReleaseMetadataEQ should be enabled if only metadata differs",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2-alpha.1+metadata"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverPreReleaseMetadataEQ",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "F8.semverPreReleaseMetadataLT should be disabled as both are equal after discarding metadata",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2-alpha.1"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverPreReleaseMetadataLT",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "F8.semverPreReleaseMetadataGT should be disabled for higher metadata cause metadata is ignored and both are equal",
  #|            "context": {
  #|                "properties": {
  #|                    "version": "1.2.2-alpha.1+metadata.2"
  #|                }
  #|            },
  #|            "toggleName":  "F8.semverPreReleaseMetadataGT",
  #|            "expectedResult": false
  #|        }
  #|    ]
  #|}

///|
let fixture_15 : String =
  #|{
  #|  "name": "15-global-constraints",
  #|  "state": {
  #|    "version": 2,
  #|    "features": [
  #|      {
  #|        "name": "F9.globalSegmentOn",
  #|        "description": "With global segment referencing constraint in on state",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "default",
  #|            "parameters": {},
  #|            "segments": [1]
  #|          }
  #|        ],
  #|        "variants": [
  #|            {
  #|                "name": "blue",
  #|                "weight": 25,
  #|                "stickiness": "customField",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                }
  #|            },
  #|            {
  #|                "name": "red",
  #|                "weight": 25,
  #|                "stickiness": "customField",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                }
  #|            },
  #|            {
  #|                "name": "green",
  #|                "weight": 25,
  #|                "stickiness": "customField",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                }
  #|            },
  #|            {
  #|                "name": "yellow",
  #|                "weight": 25,
  #|                "stickiness": "customField",
  #|                "payload": {
  #|                    "type": "string",
  #|                    "value": "val1"
  #|                }
  #|            }
  #|        ]
  #|      },
  #|      {
  #|        "name": "F9.globalSegmentOff",
  #|        "description": "With global segment referencing constraint in off state",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "default",
  #|            "parameters": {},
  #|            "segments": [2]
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "F9.globalSegmentAndConstraint",
  #|        "description": "With global segment and constraint both on",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "default",
  #|            "parameters": {},
  #|            "constraints": [
  #|              {
  #|                "contextName": "version",
  #|                "operator": "SEMVER_EQ",
  #|                "value": "1.2.2"
  #|              }
  #|            ],
  #|            "segments": [1]
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "F9.withMissingSegment",
  #|        "description": "With global segment that doesn't exist",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "default",
  #|            "parameters": {},
  #|            "constraints": [
  #|              {
  #|                "contextName": "version",
  #|                "operator": "SEMVER_EQ",
  #|                "value": "1.2.2"
  #|              }
  #|            ],
  #|            "segments": [404]
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "F9.withSeveralConstraintsAndSegments",
  #|        "description": "With several segments and constraints",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "default",
  #|            "parameters": {},
  #|            "constraints": [
  #|              {
  #|                "contextName": "customNumber",
  #|                "operator": "NUM_LT",
  #|                "value": "10"
  #|              },
  #|              {
  #|                "contextName": "version",
  #|                "operator": "SEMVER_LT",
  #|                "value": "3.2.2"
  #|              }
  #|            ],
  #|            "segments": [1, 4, 5]
  #|          }
  #|        ]
  #|      }
  #|    ],
  #|    "segments": [
  #|      {
  #|        "id": 1,
  #|        "constraints": [
  #|          {
  #|            "contextName": "version",
  #|            "operator": "SEMVER_EQ",
  #|            "value": "1.2.2"
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "id": 2,
  #|        "constraints": [
  #|          {
  #|            "contextName": "version",
  #|            "operator": "SEMVER_EQ",
  #|            "value": "3.1.4"
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "id": 3,
  #|        "constraints": [
  #|          {
  #|            "contextName": "version",
  #|            "operator": "SEMVER_EQ",
  #|            "value": "3.1.4"
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "id": 4,
  #|        "constraints": [
  #|          {
  #|            "contextName": "customName",
  #|            "operator": "STR_CONTAINS",
  #|            "values": ["Pi"]
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "id": 5,
  #|        "constraints": [
  #|          {
  #|            "contextName": "slicesLeft",
  #|            "operator": "NUM_LTE",
  #|            "value": "4"
  #|          }
  #|        ]
  #|      }
  #|    ]
  #|  },
  #|  "tests": [
  #|    {
  #|      "description": "F9.globalSegmentOn should be enabled",
  #|      "context": {
  #|        "properties": {
  #|          "version": "1.2.2"
  #|        }
  #|      },
  #|      "toggleName": "F9.globalSegmentOn",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "F9.globalSegmentOff should be disabled",
  #|      "context": {
  #|        "properties": {
  #|          "version": "3.2.2"
  #|        }
  #|      },
  #|      "toggleName": "F9.globalSegmentOff",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "F9.globalSegmentAndConstraint should be enabled",
  #|      "context": {
  #|        "properties": {
  #|          "version": "1.2.2"
  #|        }
  #|      },
  #|      "toggleName": "F9.globalSegmentAndConstraint",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "F9.withMissingSegment should force evaluation to false",
  #|      "context": {
  #|        "properties": {
  #|          "version": "1.2.2"
  #|        }
  #|      },
  #|      "toggleName": "F9.withMissingSegment",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "F9.withSeveralConstraintsAndSegments should be enabled",
  #|      "context": {
  #|        "properties": {
  #|          "version": "1.2.2",
  #|          "customNumber": "3.14",
  #|          "customName": "Pie",
  #|          "slicesLeft": "4"
  #|        }
  #|      },
  #|      "toggleName": "F9.withSeveralConstraintsAndSegments",
  #|      "expectedResult": true
  #|    }
  #|  ],
  #|  "variantTests": [
  #|    {
  #|        "description": "F9.globalSegmentOn and customField=616 yields green",
  #|        "context": {
  #|          "properties": {
  #|            "version": "1.2.2",
  #|            "customField": "616"
  #|          }
  #|        },
  #|        "toggleName": "F9.globalSegmentOn",
  #|        "expectedResult": {
  #|            "name": "green",
  #|            "payload": {
  #|                "type": "string",
  #|                "value": "val1"
  #|            },
  #|            "enabled": true,
  #|            "feature_enabled": true
  #|        }
  #|    }
  #|  ]
  #|}

///|
let fixture_16 : String =
  #|{
  #|  "name": "16-strategy-variants",
  #|  "state": {
  #|    "version": 1,
  #|    "features": [
  #|      {
  #|        "name": "Feature.strategy.variant.with.constraint",
  #|        "description": "Strategy variants based on constraint",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "variants": [
  #|              {
  #|                "name": "variantName",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "string",
  #|                  "value": "variantValue"
  #|                }
  #|              }
  #|            ],
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "a"
  #|            },
  #|            "constraints": [
  #|              {
  #|                "contextName": "environment",
  #|                "operator": "IN",
  #|                "values": ["dev"]
  #|              }
  #|            ]
  #|          }
  #|        ],
  #|        "variants": []
  #|      },
  #|      {
  #|        "name": "Feature.strategy.variant.overrides.feature.variant",
  #|        "description": "Strategy variants with feature variants",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "a"
  #|            },
  #|            "variants": [
  #|              {
  #|                "name": "variantName",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "string",
  #|                  "value": "variantValue"
  #|                }
  #|              }
  #|            ],
  #|            "constraints": [
  #|              {
  #|                "contextName": "environment",
  #|                "operator": "IN",
  #|                "values": ["dev"]
  #|              }
  #|            ]
  #|          }
  #|        ],
  #|        "variants": [
  #|          {
  #|            "name": "featureVariant",
  #|            "weight": 1,
  #|            "payload": {
  #|              "type": "string",
  #|              "value": "willBeIgnored"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.strategy.multiple.variants",
  #|        "description": "Strategy variants with multiple options",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "a"
  #|            },
  #|            "variants": [
  #|              {
  #|                "name": "variantNameA",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "string",
  #|                  "value": "variantValueA"
  #|                }
  #|              },
  #|              {
  #|                "name": "variantNameB",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "string",
  #|                  "value": "variantValueB"
  #|                }
  #|              }
  #|            ],
  #|            "constraints": []
  #|          }
  #|        ],
  #|        "variants": []
  #|      },
  #|      {
  #|        "name": "Feature.strategy.empty.variants",
  #|        "description": "Strategy variants with empty variant options",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "variants": [],
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "a"
  #|            },
  #|            "constraints": []
  #|          }
  #|        ],
  #|        "variants": []
  #|      },
  #|      {
  #|        "name": "Feature.strategy.variant.fallback",
  #|        "description": "Strategy variants fall back to feature variants",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "a"
  #|            }
  #|          }
  #|        ],
  #|        "variants": [
  #|          {
  #|            "name": "featureVariant",
  #|            "weight": 1,
  #|            "payload": {
  #|              "type": "string",
  #|              "value": "fallbackValue"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.strategy.numeric.variants",
  #|        "description": "Strategy variants with numeric payload",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "a"
  #|            },
  #|            "variants": [
  #|              {
  #|                "name": "variantNameA",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "number",
  #|                  "value": "1.2"
  #|                }
  #|              },
  #|              {
  #|                "name": "variantNameB",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "number",
  #|                  "value": "1"
  #|                }
  #|              }
  #|            ],
  #|            "constraints": []
  #|          }
  #|        ],
  #|        "variants": []
  #|      },
  #|      {
  #|        "name": "Feature.strategy.no.strategy.variants",
  #|        "description": "Toggle with no strategy variants",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "a"
  #|            },
  #|            "variants": [],
  #|            "constraints": []
  #|          }
  #|        ],
  #|        "variants": [
  #|          {
  #|            "name": "variantNameA",
  #|            "weight": 1,
  #|            "payload": {
  #|              "type": "number",
  #|              "value": "1"
  #|            }
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.strategy.variants.stickiness",
  #|        "description": "Strategy variants with stickiness inherited from the strategy",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "clientId",
  #|              "groupId": "a"
  #|            },
  #|            "variants": [
  #|              {
  #|                "name": "variantNameA",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "string",
  #|                  "value": "variantValueA"
  #|                }
  #|              },
  #|              {
  #|                "name": "variantNameB",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "string",
  #|                  "value": "variantValueB"
  #|                }
  #|              }
  #|            ],
  #|            "constraints": []
  #|          }
  #|        ],
  #|        "variants": []
  #|      }
  #|    ]
  #|  },
  #|  "variantTests": [
  #|    {
  #|      "description": "Feature.strategy.variant should return variant on enabled toggle",
  #|      "context": {
  #|        "environment": "dev"
  #|      },
  #|      "toggleName": "Feature.strategy.variant.with.constraint",
  #|      "expectedResult": {
  #|        "name": "variantName",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValue"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Feature.strategy.variant should return disabled variant on disabled toggle",
  #|      "context": {
  #|        "environment": "not-dev"
  #|      },
  #|      "toggleName": "Feature.strategy.variant.with.constraint",
  #|      "expectedResult": {
  #|        "name": "disabled",
  #|        "enabled": false,
  #|        "feature_enabled": false
  #|      }
  #|    },
  #|    {
  #|      "description": "Feature.strategy.variant.overrides.feature.variant should override feature variant",
  #|      "context": {
  #|        "environment": "dev"
  #|      },
  #|      "toggleName": "Feature.strategy.variant.overrides.feature.variant",
  #|      "expectedResult": {
  #|        "name": "variantName",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValue"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Feature.strategy.multiple.variants should choose first variant",
  #|      "context": {
  #|        "userId": "5"
  #|      },
  #|      "toggleName": "Feature.strategy.multiple.variants",
  #|      "expectedResult": {
  #|        "name": "variantNameA",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValueA"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Feature.strategy.multiple.variants should choose second variant",
  #|      "context": {
  #|        "userId": "0"
  #|      },
  #|      "toggleName": "Feature.strategy.multiple.variants",
  #|      "expectedResult": {
  #|        "name": "variantNameB",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValueB"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Feature.strategy.empty.variants should return disabled variant",
  #|      "context": {},
  #|      "toggleName": "Feature.strategy.empty.variants",
  #|      "expectedResult": {
  #|        "name": "disabled",
  #|        "enabled": false,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Feature.strategy.variant.fallback should fall back to feature variants",
  #|      "context": {},
  #|      "toggleName": "Feature.strategy.variant.fallback",
  #|      "expectedResult": {
  #|        "name": "featureVariant",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "fallbackValue"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Feature.strategy.numeric.variants should choose second variant",
  #|      "context": {
  #|        "userId": "0"
  #|      },
  #|      "toggleName": "Feature.strategy.numeric.variants",
  #|      "expectedResult": {
  #|        "name": "variantNameB",
  #|        "payload": {
  #|          "type": "number",
  #|          "value": "1"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Feature.strategy.no.strategy.variants should fall back to base variants",
  #|      "context": {
  #|        "userId": "0"
  #|      },
  #|      "toggleName": "Feature.strategy.no.strategy.variants",
  #|      "expectedResult": {
  #|        "name": "variantNameA",
  #|        "payload": {
  #|          "type": "number",
  #|          "value": "1"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Feature.strategy.variants.stickiness should inherit stickiness from the strategy - first variant",
  #|      "context": {
  #|        "properties": {
  #|          "clientId": "1"
  #|        }
  #|      },
  #|      "toggleName": "Feature.strategy.variants.stickiness",
  #|      "expectedResult": {
  #|        "name": "variantNameA",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValueA"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Feature.strategy.variants.stickiness should inherit stickiness from the strategy - second variant",
  #|      "context": {
  #|        "properties": {
  #|          "clientId": "2"
  #|        }
  #|      },
  #|      "toggleName": "Feature.strategy.variants.stickiness",
  #|      "expectedResult": {
  #|        "name": "variantNameB",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValueB"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    }
  #|  ]
  #|}

///|
let fixture_17 : String =
  #|{
  #|  "name": "17-dependent-features",
  #|  "state": {
  #|    "version": 1,
  #|    "features": [
  #|      {
  #|        "name": "parent.enabled",
  #|        "description": "Parent feature that is always enabled",
  #|        "enabled": true,
  #|        "strategies": [{
  #|          "name": "default"
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.disabled",
  #|        "description": "Parent feature that is always disabled",
  #|        "enabled": false,
  #|        "strategies": [{
  #|          "name": "default"
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.with.variant",
  #|        "description": "Parent feature with variant",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "parent"
  #|            },
  #|            "variants": [
  #|              {
  #|                "name": "parent.variant",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "string",
  #|                  "value": "variantValue"
  #|                }
  #|              }
  #|            ]
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "parent.with.constraint",
  #|        "description": "Parent feature with constraint",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "parent"
  #|            },
  #|            "constraints": [
  #|              {
  #|                "contextName": "environment",
  #|                "operator": "IN",
  #|                "values": ["prod"]
  #|
  #|              }
  #|            ],
  #|            "variants": [
  #|              {
  #|                "name": "parent.variant",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "string",
  #|                  "value": "variantValue"
  #|                }
  #|              }
  #|            ]
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "child.with.matching.constraint",
  #|        "description": "Child with parent matching constraint",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.with.constraint"
  #|        }],
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "parent"
  #|            },
  #|            "constraints": [
  #|              {
  #|                "contextName": "environment",
  #|                "operator": "IN",
  #|                "values": ["prod"]
  #|
  #|              }
  #|            ],
  #|            "variants": [
  #|              {
  #|                "name": "child.variant",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "string",
  #|                  "value": "variantValue"
  #|                }
  #|              }
  #|            ]
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "child.with.non.matching.constraint",
  #|        "description": "Child with parent not matching constraint",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.with.constraint"
  #|        }],
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "parent"
  #|            },
  #|            "constraints": [
  #|              {
  #|                "contextName": "environment",
  #|                "operator": "IN",
  #|                "values": ["dev"]
  #|
  #|              }
  #|            ],
  #|            "variants": [
  #|              {
  #|                "name": "child.variant",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "string",
  #|                  "value": "variantValue"
  #|                }
  #|              }
  #|            ]
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "parent.with.cycle",
  #|        "description": "Parent with cycle to child",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "child.with.cycle"
  #|        }],
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "parent"
  #|            },
  #|            "variants": [
  #|              {
  #|                "name": "parent.variant",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "string",
  #|                  "value": "variantValue"
  #|                }
  #|              }
  #|            ]
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "child.with.cycle",
  #|        "description": "Child with cycle to parent",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.with.cycle"
  #|        }],
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "parent"
  #|            },
  #|            "variants": [
  #|              {
  #|                "name": "parent.variant",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "string",
  #|                  "value": "variantValue"
  #|                }
  #|              }
  #|            ]
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "child.with.transitive.dependency",
  #|        "description": "Child with transitive dependency",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.enabled.child.enabled"
  #|        }],
  #|        "strategies": [
  #|          {
  #|            "name": "flexibleRollout",
  #|            "parameters": {
  #|              "rollout": "100",
  #|              "stickiness": "default",
  #|              "groupId": "parent"
  #|            },
  #|            "variants": [
  #|              {
  #|                "name": "parent.variant",
  #|                "weight": 1,
  #|                "payload": {
  #|                  "type": "string",
  #|                  "value": "variantValue"
  #|                }
  #|              }
  #|            ]
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "parent.explicitly.enabled.child.enabled",
  #|        "description": "Parent explicitly enabled, child enabled",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.enabled",
  #|          "enabled": true
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.enabled.child.enabled",
  #|        "description": "Parent enabled, child enabled",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.enabled"
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.enabled.child.disabled",
  #|        "description": "Parent enabled, child disabled",
  #|        "enabled": false,
  #|        "dependencies": [{
  #|          "feature": "parent.enabled"
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.disabled.child.enabled",
  #|        "description": "Parent disabled, child enabled",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.disabled"
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.disabled.child.disabled",
  #|        "description": "Parent disabled, child disabled",
  #|        "enabled": false,
  #|        "dependencies": [{
  #|          "feature": "parent.disabled"
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.default.variant.child.enabled",
  #|        "description": "Parent enabled with no explicit variant, child enabled",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.enabled",
  #|          "variants": ["disabled"]
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.disabled.satisfied.child.enabled",
  #|        "description": "Parent disabled expectation satisfied, child enabled",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.disabled",
  #|          "enabled": false
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.disabled.not.satisfied.child.enabled",
  #|        "description": "Parent disabled expectation not satisfied, child enabled",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.enabled",
  #|          "enabled": false
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.single.variant.child.enabled",
  #|        "description": "Parent single variant match, child enabled",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.with.variant",
  #|          "variants": ["parent.variant"]
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.multiple.variants.child.enabled",
  #|        "description": "Parent multiples variants match, child enabled",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.with.variant",
  #|          "variants": ["parent.variant", "nonmatching.variant"]
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.empty.variants.child.enabled",
  #|        "description": "Parent empty variants match, child enabled",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.with.variant",
  #|          "variants": []
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.non.matching.variant.child.enabled",
  #|        "description": "Parent non matching variant, child enabled",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.with.variant",
  #|          "variants": ["nonmatching.variant"]
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "multiple.parents.satisfied.child.enabled",
  #|        "description": "Multiple parents satisfied, child enabled",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.enabled"
  #|        }, {
  #|          "feature": "parent.disabled",
  #|          "enabled": false
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "multiple.parents.not.satisfied.child.enabled",
  #|        "description": "Multiple parents not satisfied, child enabled",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.enabled"
  #|        }, {
  #|          "feature": "parent.disabled"
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parents.not.exist.child.enabled",
  #|        "description": "Parent does not exist, child enabled",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.not.exist"
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.disabled.child.expects.disabled.variant",
  #|        "description": "The parent is disabled. The child expects the parent's variant to be \"disabled\".",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.disabled",
  #|          "variants": ["disabled"]
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": []
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.with.constraint.child.expects.disabled",
  #|        "description": "The parent is enabled and has a constraint. The child expects the parent to be disabled.",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.with.constraint",
  #|          "enabled": false
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      },
  #|      {
  #|        "name": "parent.with.constraint.child.expects.disabled.variant",
  #|        "description": "The parent is enabled and has a constraint. The child expects the parent's variant to be \"disabled\".",
  #|        "enabled": true,
  #|        "dependencies": [{
  #|          "feature": "parent.with.constraint",
  #|          "variants": ["disabled"]
  #|        }],
  #|        "strategies": [{
  #|          "name": "flexibleRollout",
  #|          "parameters": {
  #|            "rollout": "100",
  #|            "stickiness": "default",
  #|            "groupId": "groupId"
  #|          },
  #|          "variants": [
  #|            {
  #|              "name": "child.variant",
  #|              "weight": 1,
  #|              "payload": {
  #|                "type": "string",
  #|                "value": "variantValue"
  #|              }
  #|            }
  #|          ]
  #|        }]
  #|      }
  #|    ]
  #|  },
  #|  "tests": [
  #|    {
  #|      "description": "Both parent and child must be enabled for the child to be enabled.",
  #|      "context": {},
  #|      "toggleName": "parent.enabled.child.enabled",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Both explicitly enabled parent and child must be enabled for the child to be enabled.",
  #|      "context": {},
  #|      "toggleName": "parent.explicitly.enabled.child.enabled",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "If parent is enabled but child is not, the child remains disabled.",
  #|      "context": {},
  #|      "toggleName": "parent.enabled.child.disabled",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "If parent is disabled, the child is also disabled, irrespective of its own state.",
  #|      "context": {},
  #|      "toggleName": "parent.disabled.child.enabled",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Both parent and child being disabled results in the child being disabled.",
  #|      "context": {},
  #|      "toggleName": "parent.disabled.child.disabled",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Child is enabled only if the parent is expectedly disabled and indeed is.",
  #|      "context": {},
  #|      "toggleName": "parent.disabled.satisfied.child.enabled",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Child is disabled if the parent is expected to be disabled but is actually enabled.",
  #|      "context": {},
  #|      "toggleName": "parent.disabled.not.satisfied.child.enabled",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Child is enabled if its parent matches a specific variant.",
  #|      "context": {},
  #|      "toggleName": "parent.single.variant.child.enabled",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Child is enabled if its parent matches any of the specified variants.",
  #|      "context": {},
  #|      "toggleName": "parent.multiple.variants.child.enabled",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Child is enabled if the parent is enabled, regardless of empty variant dependencies.",
  #|      "context": {},
  #|      "toggleName": "parent.empty.variants.child.enabled",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Child is disabled if the parent's variant does not match the specified one.",
  #|      "context": {},
  #|      "toggleName": "parent.non.matching.variant.child.enabled",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Child is enabled if all of its multiple parents are enabled.",
  #|      "context": {},
  #|      "toggleName": "multiple.parents.satisfied.child.enabled",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Child is disabled if any one of its multiple parents is disabled.",
  #|      "context": {},
  #|      "toggleName": "multiple.parents.not.satisfied.child.enabled",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Child is disabled if the specified parent does not exist.",
  #|      "context": {},
  #|      "toggleName": "parents.not.exist.child.enabled",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Child is disabled if there's a cyclic dependency with the parent.",
  #|      "context": {},
  #|      "toggleName": "child.with.cycle",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Child is disabled if a transitive dependency exists.",
  #|      "context": {},
  #|      "toggleName": "child.with.transitive.dependency",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Child is enabled if its parent is enabled with child context.",
  #|      "context": {
  #|        "environment": "prod"
  #|      },
  #|      "toggleName": "child.with.matching.constraint",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Child is disabled if its parent is disabled with child context.",
  #|      "context": {
  #|        "environment": "dev"
  #|      },
  #|      "toggleName": "child.with.non.matching.constraint",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Child is enabled if its parent's default variant is satisfied.",
  #|      "context": {},
  #|      "toggleName": "parent.default.variant.child.enabled",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Child is disabled if the parent is disabled, even if the child's expected variant is the disabled variant",
  #|      "context": {},
  #|      "toggleName": "parent.disabled.child.expects.disabled.variant",
  #|      "expectedResult": false
  #|    },
  #|    {
  #|      "description": "Child is enabled if the parent is expected to be disabled and the parent's constraint does not match.",
  #|      "context": {
  #|        "environment": "dev"
  #|      },
  #|      "toggleName": "parent.with.constraint.child.expects.disabled",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Child is disabled when it requires the parent's variant to be \"disabled\" and the parent is off because its constraint does not match.",
  #|      "context": {
  #|        "environment": "dev"
  #|      },
  #|      "toggleName": "parent.with.constraint.child.expects.disabled.variant",
  #|      "expectedResult": false
  #|    }
  #|  ],
  #|  "variantTests": [
  #|    {
  #|      "description": "Child yields its variant when both parent and child are enabled.",
  #|      "context": {},
  #|      "toggleName": "parent.enabled.child.enabled",
  #|      "expectedResult": {
  #|        "name": "child.variant",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValue"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields its variant when both explicitly enabled parent and child are enabled.",
  #|      "context": {},
  #|      "toggleName": "parent.explicitly.enabled.child.enabled",
  #|      "expectedResult": {
  #|        "name": "child.variant",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValue"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields a disabled variant when the parent is enabled, but the child is not.",
  #|      "context": {},
  #|      "toggleName": "parent.enabled.child.disabled",
  #|      "expectedResult": {
  #|        "name": "disabled",
  #|        "enabled": false,
  #|        "feature_enabled": false
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields a disabled variant when the parent is disabled, even if the child is enabled.",
  #|      "context": {},
  #|      "toggleName": "parent.disabled.child.enabled",
  #|      "expectedResult": {
  #|        "name": "disabled",
  #|        "enabled": false,
  #|        "feature_enabled": false
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields a disabled variant when both the parent and child are disabled.",
  #|      "context": {},
  #|      "toggleName": "parent.disabled.child.disabled",
  #|      "expectedResult": {
  #|        "name": "disabled",
  #|        "enabled": false,
  #|        "feature_enabled": false
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields its variant when the parent's disabled state is as expected.",
  #|      "context": {},
  #|      "toggleName": "parent.disabled.satisfied.child.enabled",
  #|      "expectedResult": {
  #|        "name": "child.variant",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValue"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields a disabled variant when the parent's disabled state is not as expected.",
  #|      "context": {},
  #|      "toggleName": "parent.disabled.not.satisfied.child.enabled",
  #|      "expectedResult": {
  #|        "name": "disabled",
  #|        "enabled": false,
  #|        "feature_enabled": false
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields its variant when the parent matches a specific variant.",
  #|      "context": {},
  #|      "toggleName": "parent.single.variant.child.enabled",
  #|      "expectedResult": {
  #|        "name": "child.variant",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValue"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields its variant when the parent matches any given variant.",
  #|      "context": {},
  #|      "toggleName": "parent.multiple.variants.child.enabled",
  #|      "expectedResult": {
  #|        "name": "child.variant",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValue"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields its variant when the parent is enabled, even with empty variant dependencies.",
  #|      "context": {},
  #|      "toggleName": "parent.empty.variants.child.enabled",
  #|      "expectedResult": {
  #|        "name": "child.variant",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValue"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields a disabled variant if the parent's variant doesn't match the required one.",
  #|      "context": {},
  #|      "toggleName": "parent.non.matching.variant.child.enabled",
  #|      "expectedResult": {
  #|        "name": "disabled",
  #|        "enabled": false,
  #|        "feature_enabled": false
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields its variant when all its parents are enabled.",
  #|      "context": {},
  #|      "toggleName": "multiple.parents.satisfied.child.enabled",
  #|      "expectedResult": {
  #|        "name": "child.variant",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValue"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields a disabled variant if any of its parents is disabled.",
  #|      "context": {},
  #|      "toggleName": "multiple.parents.not.satisfied.child.enabled",
  #|      "expectedResult": {
  #|        "name": "disabled",
  #|        "enabled": false,
  #|        "feature_enabled": false
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields a disabled variant in the absence of a specified parent.",
  #|      "context": {},
  #|      "toggleName": "parents.not.exist.child.enabled",
  #|      "expectedResult": {
  #|        "name": "disabled",
  #|        "enabled": false,
  #|        "feature_enabled": false
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields a disabled variant due to a cyclic dependency with the parent.",
  #|      "context": {},
  #|      "toggleName": "child.with.cycle",
  #|      "expectedResult": {
  #|        "name": "disabled",
  #|        "enabled": false,
  #|        "feature_enabled": false
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields a disabled variant because of a transitive dependency.",
  #|      "context": {},
  #|      "toggleName": "child.with.transitive.dependency",
  #|      "expectedResult": {
  #|        "name": "disabled",
  #|        "enabled": false,
  #|        "feature_enabled": false
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields its variant when parent is enabled with child context.",
  #|      "context": {
  #|        "environment": "prod"
  #|      },
  #|      "toggleName": "child.with.matching.constraint",
  #|      "expectedResult": {
  #|        "name": "child.variant",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValue"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields a disabled variant when parent is disabled with child context.",
  #|      "context": {
  #|        "environment": "dev"
  #|      },
  #|      "toggleName": "child.with.non.matching.constraint",
  #|      "expectedResult": {
  #|        "name": "disabled",
  #|        "enabled": false,
  #|        "feature_enabled": false
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields its variant when the parent's default variant is met.",
  #|      "context": {},
  #|      "toggleName": "parent.default.variant.child.enabled",
  #|      "expectedResult": {
  #|        "name": "child.variant",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValue"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields its variant when the parent is expected to be disabled and the parent's constraint does not match.",
  #|      "context": {
  #|        "environment": "dev"
  #|      },
  #|      "toggleName": "parent.with.constraint.child.expects.disabled",
  #|      "expectedResult": {
  #|        "name": "child.variant",
  #|        "payload": {
  #|          "type": "string",
  #|          "value": "variantValue"
  #|        },
  #|        "enabled": true,
  #|        "feature_enabled": true
  #|      }
  #|    },
  #|    {
  #|      "description": "Child yields a disabled variant when it requires the parent's variant to be \"disabled\" and the parent is off because its constraint does not match.",
  #|      "context": {
  #|        "environment": "dev"
  #|      },
  #|      "toggleName": "parent.with.constraint.child.expects.disabled.variant",
  #|      "expectedResult": {
  #|        "name": "disabled",
  #|        "enabled": false,
  #|        "feature_enabled": false
  #|      }
  #|    }
  #|  ]
  #|}

///|
let fixture_18 : String =
  #|{
  #|  "name": "18-utf8-flag-names",
  #|  "state": {
  #|    "version": 1,
  #|    "features": [
  #|      {
  #|        "name": "Feature.UTF-8.Hellø_Wørld",
  #|        "description": "Enabled basic UTF-8 toggle",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "default"
  #|          }
  #|        ]
  #|      },
  #|      {
  #|        "name": "Feature.UTF-8.😊_φriend_你好_🌍",
  #|        "description": "Enabled complex UTF-8 toggle",
  #|        "enabled": true,
  #|        "strategies": [
  #|          {
  #|            "name": "default"
  #|          }
  #|        ]
  #|      }
  #|    ]
  #|  },
  #|  "tests": [
  #|    {
  #|      "description": "Feature.UTF-8.Hellø_Wørld feature toggle should be enabled",
  #|      "context": {},
  #|      "toggleName": "Feature.UTF-8.Hellø_Wørld",
  #|      "expectedResult": true
  #|    },
  #|    {
  #|      "description": "Feature.UTF-8.😊_φriend_你好_🌍 feature toggle should be enabled",
  #|      "context": {},
  #|      "toggleName": "Feature.UTF-8.😊_φriend_你好_🌍",
  #|      "expectedResult": true
  #|    }
  #|  ]
  #|}

///|
let fixture_19 : String =
  #|{
  #|    "name": "19-delta-api-hydration",
  #|    "state": {
  #|        "events": [
  #|            {
  #|                "eventId": 1,
  #|                "type": "hydration",
  #|                "segments": [
  #|                    {
  #|                        "id": 1,
  #|                        "name": "delta.api.hydration.segment",
  #|                        "constraints": [
  #|                            {
  #|                                "values": [
  #|                                    "abc",
  #|                                    "edf",
  #|                                    "gbd"
  #|                                ],
  #|                                "inverted": false,
  #|                                "operator": "IN",
  #|                                "contextName": "appName",
  #|                                "caseInsensitive": false
  #|                            }
  #|                        ]
  #|                    }
  #|                ],
  #|                "features": [
  #|                    {
  #|                        "impressionData": false,
  #|                        "enabled": true,
  #|                        "name": "delta.api.hydration",
  #|                        "description": null,
  #|                        "project": "default",
  #|                        "stale": false,
  #|                        "type": "release",
  #|                        "variants": [],
  #|                        "segments": [
  #|                            1
  #|                        ],
  #|                        "strategies": [
  #|                            {
  #|                                "name": "flexibleRollout",
  #|                                "constraints": [],
  #|                                "parameters": {
  #|                                    "groupId": "delta.api.hydration",
  #|                                    "rollout": "100",
  #|                                    "stickiness": "default"
  #|                                },
  #|                                "variants": []
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            }
  #|        ]
  #|    },
  #|    "tests": [
  #|        {
  #|            "description": "Hydration feature should be enabled when context criteria are met",
  #|            "context": {
  #|                "appName": "abc"
  #|            },
  #|            "toggleName": "delta.api.hydration",
  #|            "expectedResult": true
  #|        }
  #|    ]
  #|}

///|
let fixture_20 : String =
  #|{
  #|    "name": "20-delta-api-events",
  #|    "state": {
  #|        "events": [
  #|            {
  #|                "eventId": 1,
  #|                "type": "feature-updated",
  #|                "feature": {
  #|                    "impressionData": false,
  #|                    "enabled": true,
  #|                    "name": "delta.api.events.updated.1",
  #|                    "description": null,
  #|                    "project": "default",
  #|                    "stale": false,
  #|                    "type": "release",
  #|                    "variants": [],
  #|                    "strategies": [
  #|                        {
  #|                            "name": "default"
  #|                        }
  #|                    ]
  #|                }
  #|            },
  #|            {
  #|                "eventId": 2,
  #|                "type": "feature-updated",
  #|                "feature": {
  #|                    "impressionData": false,
  #|                    "enabled": true,
  #|                    "name": "delta.api.events.updated.2",
  #|                    "description": null,
  #|                    "project": "default",
  #|                    "stale": false,
  #|                    "type": "release",
  #|                    "variants": [],
  #|                    "strategies": [
  #|                        {
  #|                            "name": "default"
  #|                        }
  #|                    ]
  #|                }
  #|            },
  #|            {
  #|                "eventId": 3,
  #|                "type": "feature-removed",
  #|                "featureName": "delta.api.events.updated.2",
  #|                "project" : "default"
  #|            },
  #|            {
  #|            "eventId": 4,
  #|            "type": "segment-updated",
  #|            "segment": {
  #|                "id": 1,
  #|                "name": "my-segment",
  #|                "constraints": [
  #|                        {
  #|                            "values": [
  #|                                "abc",
  #|                                "edf",
  #|                                "gbd"
  #|                            ],
  #|                            "inverted": false,
  #|                            "operator": "IN",
  #|                            "contextName": "appName",
  #|                            "caseInsensitive": false
  #|                        }
  #|                    ]
  #|                }
  #|            },
  #|            {
  #|                "eventId": 5,
  #|                "type": "feature-updated",
  #|                "feature": {
  #|                    "impressionData": false,
  #|                    "enabled": true,
  #|                    "name": "delta.api.events.updated.3",
  #|                    "description": null,
  #|                    "project": "default",
  #|                    "stale": false,
  #|                    "type": "release",
  #|                    "variants": [],
  #|                    "strategies": [
  #|                        {
  #|                            "name": "default",
  #|                            "segments": [1]
  #|                        }
  #|                    ]
  #|                }
  #|            }
  #|        ]
  #|    },
  #|    "tests": [
  #|        {
  #|            "description": "delta.api.events.updated.1 should be enabled",
  #|            "context": {},
  #|            "toggleName": "delta.api.events.updated.1",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "delta.api.events.updated.2 should be disabled",
  #|            "context": {},
  #|            "toggleName": "delta.api.events.updated.2",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "delta.api.events.updated.3 should be enabled with segment",
  #|            "context": { "appName": "abc" },
  #|            "toggleName": "delta.api.events.updated.3",
  #|            "expectedResult": true
  #|        }
  #|    ]
  #|}

///|
let fixture_21 : String =
  #|{
  #|    "name": "21-regex-constraint-operators",
  #|    "state": {
  #|        "version": 1,
  #|        "features": [
  #|            {
  #|                "name": "regex.case.sensitive",
  #|                "description": "Regex constraints are case sensitive by default",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^cat$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "invalid-regex-defaults-to-false",
  #|                "description": "Invalid regex always results in toggle being disabled",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "(regex"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R01.literal_and_anchors",
  #|                "description": "Anchors ^ $ basic email-ish check",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^[^@]+@[^@]+$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R01.literal_and_anchors.referencing.property",
  #|                "description": "Anchors ^ $ basic email-ish check",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "nested",
  #|                                "operator": "REGEX",
  #|                                "value": "^[^@]+@[^@]+$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R02.perl_digit_class",
  #|                "description": "\\d and quantifiers",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^user\\d{3}$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R03.ascii_class",
  #|                "description": "[[:alpha:]] and +",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^[[:alpha:]]+$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R04.word_boundary_ascii",
  #|                "description": "\\b word boundary (ASCII semantics)",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "\\bcat\\b"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R05.alternation_prefer_left",
  #|                "description": "Alternation prefers left branch",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^(foo|fo)$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R06.grouping_and_optional",
  #|                "description": "Capturing group + optional ?",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^(ab)?c$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R07.repetition_range_limits",
  #|                "description": "Bounded repetition {n,m}",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^a{2,4}$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R08.greedy_vs_nongreedy",
  #|                "description": "Non-greedy quantifier *?",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^a.*?b$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R09.inline_flag_i",
  #|                "description": "Inline (?i) case-insensitive",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^(?i)abc$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Global.case.insensitive",
  #|                "description": "Global case-insensitive flag (should work the same as inline (?i))",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^abc$",
  #|                                "caseInsensitive": true
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "Inverted.constraint",
  #|                "description": "Inverted regex constraint (should enable when regex does NOT match)",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^abc$",
  #|                                "inverted": true
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R10.inline_flag_m",
  #|                "description": "Inline (?m) multiline anchors",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "(?m)^foo$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R11.inline_flag_s_dotall",
  #|                "description": "Inline (?s) dot matches newline",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^(?s)a.b$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R90.reject_lookahead",
  #|                "description": "Should be rejected by server validation (lookahead not supported in RE2)",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^(?=a)b$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "R91.reject_backreference",
  #|                "description": "Should be rejected by server validation (backrefs not supported in RE2)",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "userId",
  #|                                "operator": "REGEX",
  #|                                "value": "^(a)\\1$"
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            }
  #|        ]
  #|    },
  #|    "tests": [
  #|        {
  #|            "description": "Basic email match should be enabled when regex matches",
  #|            "context": {
  #|                "userId": "test@example.com"
  #|            },
  #|            "toggleName": "R01.literal_and_anchors",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Broken regex should not match anything",
  #|            "context": {
  #|                "userId": "not-an-email"
  #|            },
  #|            "toggleName": "R01.literal_and_anchors",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Invalid regex should result in toggle being disabled",
  #|            "context": {
  #|                "userId": "any-value"
  #|            },
  #|            "toggleName": "invalid-regex-defaults-to-false",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Null value should result in toggle being disabled",
  #|            "context": {
  #|                "properties": {
  #|                    "nested": null
  #|                }
  #|            },
  #|            "toggleName": "R01.literal_and_anchors.referencing.property",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Sanity check for 'Null value should result in toggle being disabled'",
  #|            "context": {
  #|                "properties": {
  #|                    "nested": "test@example.com"
  #|                }
  #|            },
  #|            "toggleName": "R01.literal_and_anchors.referencing.property",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Undefined value should result in toggle being disabled",
  #|            "context": {},
  #|            "toggleName": "R01.literal_and_anchors",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "R01 matches basic email-ish",
  #|            "context": {
  #|                "userId": "test@example.com"
  #|            },
  #|            "toggleName": "R01.literal_and_anchors",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "R01 rejects missing @",
  #|            "context": {
  #|                "userId": "not-an-email"
  #|            },
  #|            "toggleName": "R01.literal_and_anchors",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "R02 matches user + 3 digits",
  #|            "context": {
  #|                "userId": "user123"
  #|            },
  #|            "toggleName": "R02.perl_digit_class",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "R02 rejects wrong digit count",
  #|            "context": {
  #|                "userId": "user12"
  #|            },
  #|            "toggleName": "R02.perl_digit_class",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "R03 matches ASCII alpha only",
  #|            "context": {
  #|                "userId": "AlphaBeta"
  #|            },
  #|            "toggleName": "R03.ascii_class",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "R03 rejects digits",
  #|            "context": {
  #|                "userId": "Alpha1"
  #|            },
  #|            "toggleName": "R03.ascii_class",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "R04 matches whole word cat",
  #|            "context": {
  #|                "userId": "a cat b"
  #|            },
  #|            "toggleName": "R04.word_boundary_ascii",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "R04 does not match inside 'concatenate'",
  #|            "context": {
  #|                "userId": "concatenate"
  #|            },
  #|            "toggleName": "R04.word_boundary_ascii",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "R05 matches foo",
  #|            "context": {
  #|                "userId": "foo"
  #|            },
  #|            "toggleName": "R05.alternation_prefer_left",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "R05 matches fo",
  #|            "context": {
  #|                "userId": "fo"
  #|            },
  #|            "toggleName": "R05.alternation_prefer_left",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "R05 rejects f",
  #|            "context": {
  #|                "userId": "f"
  #|            },
  #|            "toggleName": "R05.alternation_prefer_left",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "R06 matches abc (optional 'ab')",
  #|            "context": {
  #|                "userId": "abc"
  #|            },
  #|            "toggleName": "R06.grouping_and_optional",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "R06 matches c",
  #|            "context": {
  #|                "userId": "c"
  #|            },
  #|            "toggleName": "R06.grouping_and_optional",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "R06 rejects ac (missing b)",
  #|            "context": {
  #|                "userId": "ac"
  #|            },
  #|            "toggleName": "R06.grouping_and_optional",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "R07 matches aaaa (4 a's)",
  #|            "context": {
  #|                "userId": "aaaa"
  #|            },
  #|            "toggleName": "R07.repetition_range_limits",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "R07 rejects a (too short)",
  #|            "context": {
  #|                "userId": "a"
  #|            },
  #|            "toggleName": "R07.repetition_range_limits",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "R07 rejects aaaaa (too long)",
  #|            "context": {
  #|                "userId": "aaaaa"
  #|            },
  #|            "toggleName": "R07.repetition_range_limits",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "R08 non-greedy still matches full string ending in b",
  #|            "context": {
  #|                "userId": "a___b___b"
  #|            },
  #|            "toggleName": "R08.greedy_vs_nongreedy",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "R08 rejects missing ending b",
  #|            "context": {
  #|                "userId": "a___b___c"
  #|            },
  #|            "toggleName": "R08.greedy_vs_nongreedy",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "R09 (?i) matches different case",
  #|            "context": {
  #|                "userId": "AbC"
  #|            },
  #|            "toggleName": "R09.inline_flag_i",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "R09 (?i) rejects extra chars",
  #|            "context": {
  #|                "userId": "zAbCz"
  #|            },
  #|            "toggleName": "R09.inline_flag_i",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Global case-insensitive matches different case",
  #|            "context": {
  #|                "userId": "AbC"
  #|            },
  #|            "toggleName": "Global.case.insensitive",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Regex constraint is case sensitive by default",
  #|            "context": {
  #|                "userId": "Cat"
  #|            },
  #|            "toggleName": "regex.case.sensitive",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Regex constraint is case sensitive by default (validate)",
  #|            "context": {
  #|                "userId": "cat"
  #|            },
  #|            "toggleName": "regex.case.sensitive",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Inverted constraint should enable when regex does not match",
  #|            "context": {
  #|                "userId": "xyz"
  #|            },
  #|            "toggleName": "Inverted.constraint",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Inverted constraint should disable when regex matches",
  #|            "context": {
  #|                "userId": "abc"
  #|            },
  #|            "toggleName": "Inverted.constraint",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "R10 (?m) matches line 'foo' inside multiline string",
  #|            "context": {
  #|                "userId": "x\nfoo\ny"
  #|            },
  #|            "toggleName": "R10.inline_flag_m",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "R10 without foo line would fail",
  #|            "context": {
  #|                "userId": "x\nfo\ny"
  #|            },
  #|            "toggleName": "R10.inline_flag_m",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "R11 (?s) dot matches newline",
  #|            "context": {
  #|                "userId": "a\nb"
  #|            },
  #|            "toggleName": "R11.inline_flag_s_dotall",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "R90 lookahead should be rejected upstream; if it leaks through, it must not enable",
  #|            "context": {
  #|                "userId": "ab"
  #|            },
  #|            "toggleName": "R90.reject_lookahead",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "R91 backreference should be rejected upstream; if it leaks through, it must not enable",
  #|            "context": {
  #|                "userId": "aa"
  #|            },
  #|            "toggleName": "R91.reject_backreference",
  #|            "expectedResult": false
  #|        }
  #|    ]
  #|}

///|
let fixture_22 : String =
  #|{
  #|    "name": "22-cidr-constraint-operator",
  #|    "state": {
  #|        "version": 1,
  #|        "features": [
  #|            {
  #|                "name": "CIDR.exact.match",
  #|                "description": "Exact IP match using IN_CIDR",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "remoteAddress",
  #|                                "operator": "IN_CIDR",
  #|                                "values": ["127.0.0.1"]
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "CIDR.range.match",
  #|                "description": "CIDR range match using IN_CIDR",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "remoteAddress",
  #|                                "operator": "IN_CIDR",
  #|                                "values": ["160.33.0.0/16"]
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "CIDR.mixed.values",
  #|                "description": "Invalid values should be ignored when valid ones exist",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "remoteAddress",
  #|                                "operator": "IN_CIDR",
  #|                                "values": ["127.invalid", "192.168.1.0/24"]
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "CIDR.invalid.only",
  #|                "description": "Only invalid values should not match anything",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "remoteAddress",
  #|                                "operator": "IN_CIDR",
  #|                                "values": ["127.invalid"]
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "CIDR.ipv6.exact.match",
  #|                "description": "Exact IPv6 match using IN_CIDR",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "remoteAddress",
  #|                                "operator": "IN_CIDR",
  #|                                "values": ["2001:db8::1"]
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "CIDR.ipv6.range.match",
  #|                "description": "IPv6 CIDR range match using IN_CIDR",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "remoteAddress",
  #|                                "operator": "IN_CIDR",
  #|                                "values": ["2001:db8::/32"]
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            },
  #|            {
  #|                "name": "CIDR.ipv6.mixed.values",
  #|                "description": "Invalid values should be ignored when valid IPv6 CIDR exists",
  #|                "enabled": true,
  #|                "strategies": [
  #|                    {
  #|                        "name": "default",
  #|                        "parameters": {},
  #|                        "constraints": [
  #|                            {
  #|                                "contextName": "remoteAddress",
  #|                                "operator": "IN_CIDR",
  #|                                "values": ["bad::cidr", "2001:db8::/32"]
  #|                            }
  #|                        ]
  #|                    }
  #|                ]
  #|            }
  #|        ]
  #|    },
  #|    "tests": [
  #|        {
  #|            "description": "Exact IP match should be enabled",
  #|            "context": {
  #|                "remoteAddress": "127.0.0.1"
  #|            },
  #|            "toggleName": "CIDR.exact.match",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Exact IP mismatch should be disabled",
  #|            "context": {
  #|                "remoteAddress": "127.0.0.2"
  #|            },
  #|            "toggleName": "CIDR.exact.match",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "CIDR range should enable matching IP",
  #|            "context": {
  #|                "remoteAddress": "160.33.0.33"
  #|            },
  #|            "toggleName": "CIDR.range.match",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "CIDR range should disable non-matching IP",
  #|            "context": {
  #|                "remoteAddress": "160.34.0.1"
  #|            },
  #|            "toggleName": "CIDR.range.match",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Valid CIDR should match even when invalid entries exist",
  #|            "context": {
  #|                "remoteAddress": "192.168.1.42"
  #|            },
  #|            "toggleName": "CIDR.mixed.values",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Invalid-only values should not match",
  #|            "context": {
  #|                "remoteAddress": "127.0.0.1"
  #|            },
  #|            "toggleName": "CIDR.invalid.only",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Missing remoteAddress should not match",
  #|            "context": {},
  #|            "toggleName": "CIDR.range.match",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Exact IPv6 match should be enabled",
  #|            "context": {
  #|                "remoteAddress": "2001:db8::1"
  #|            },
  #|            "toggleName": "CIDR.ipv6.exact.match",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "Exact IPv6 mismatch should be disabled",
  #|            "context": {
  #|                "remoteAddress": "2001:db8::2"
  #|            },
  #|            "toggleName": "CIDR.ipv6.exact.match",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "IPv6 CIDR range should enable matching IP",
  #|            "context": {
  #|                "remoteAddress": "2001:db8:0:1::42"
  #|            },
  #|            "toggleName": "CIDR.ipv6.range.match",
  #|            "expectedResult": true
  #|        },
  #|        {
  #|            "description": "IPv6 CIDR range should disable non-matching IP",
  #|            "context": {
  #|                "remoteAddress": "2001:db9::1"
  #|            },
  #|            "toggleName": "CIDR.ipv6.range.match",
  #|            "expectedResult": false
  #|        },
  #|        {
  #|            "description": "Valid IPv6 CIDR should match even when invalid entries exist",
  #|            "context": {
  #|                "remoteAddress": "2001:db8::abcd"
  #|            },
  #|            "toggleName": "CIDR.ipv6.mixed.values",
  #|            "expectedResult": true
  #|        }
  #|    ]
  #|}

///|
pub(all) struct Fixture {
  file : String
  required : Bool
  source : String
}

///|
pub fn revision() -> String {
  "9ef6efa01feabeb699857192ad8106fd7d990235"
}

///|
pub fn suites() -> Array[Fixture] {
  [
    { file: "01-simple-examples.json", required: true, source: fixture_01, },
    {
      file: "02-user-with-id-strategy.json",
      required: true,
      source: fixture_02,
    },
    {
      file: "03-gradual-rollout-user-id-strategy.json",
      required: true,
      source: fixture_03,
    },
    {
      file: "04-gradual-rollout-session-id-strategy.json",
      required: true,
      source: fixture_04,
    },
    {
      file: "05-gradual-rollout-random-strategy.json",
      required: true,
      source: fixture_05,
    },
    {
      file: "06-remote-address-strategy.json",
      required: false,
      source: fixture_06,
    },
    { file: "07-multiple-strategies.json", required: true, source: fixture_07, },
    { file: "08-variants.json", required: true, source: fixture_08, },
    {
      file: "09-strategy-constraints.json",
      required: true,
      source: fixture_09,
    },
    {
      file: "10-flexible-rollout-strategy.json",
      required: true,
      source: fixture_10,
    },
    {
      file: "11-strategy-constraints-edge-cases.json",
      required: true,
      source: fixture_11,
    },
    { file: "12-custom-stickiness.json", required: true, source: fixture_12, },
    {
      file: "13-constraint-operators.json",
      required: false,
      source: fixture_13,
    },
    {
      file: "14-constraint-semver-operators.json",
      required: false,
      source: fixture_14,
    },
    { file: "15-global-constraints.json", required: false, source: fixture_15, },
    { file: "16-strategy-variants.json", required: false, source: fixture_16, },
    { file: "17-dependent-features.json", required: false, source: fixture_17, },
    { file: "18-utf8-flag-names.json", required: true, source: fixture_18, },
    {
      file: "19-delta-api-hydration.json",
      required: false,
      source: fixture_19,
    },
    { file: "20-delta-api-events.json", required: false, source: fixture_20, },
    {
      file: "21-regex-constraint-operators.json",
      required: false,
      source: fixture_21,
    },
    {
      file: "22-cidr-constraint-operators.json",
      required: false,
      source: fixture_22,
    },
  ]
}
